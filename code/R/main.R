# IMPORTS -----------------------------------------------------------------

library(logger)
library(optparse)
library(timetk)

set.seed(2021)
log_level(level = "INFO")

source("code/R/get_data.R")
source("code/R/tsa.R")
source("code/R/process_data.R")
source("code/R/plotting_utils.R")

### Note, change defaults by environment variables that can be injected to the code if running
### as a container somewhere

# CONFIGURATION -----------------------------------------------------------------


option_list <- list(
  make_option(
    c("-i", "--input_data"),
    default = 'input/data',
    help = "Default input data directory[default]",
    metavar = "character"
  ),
  make_option(
    c("-s", "--sales_file"),
    default = "sales_master.csv",
    help = "Name of the sales file",
    metavar = "character"
  ),
  make_option(
    c("-p", "--product_file"),
    default = "product_table.csv",
    help = "Name of the sales file",
    metavar = "character"
  ),
  make_option(
    c("-o", "--output_data"),
    default = 'input/output',
    help = "Default output data directory[default]",
    metavar = "character"
  ),
  make_option(
    c("-m", "--model"),
    default = 'models/',
    help = "Model directory",
    metavar = "character"
  )
)


# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults


argument_parser <- parse_args(OptionParser(option_list = option_list))



# DATA LOADING ------------------------------------------------------------


### We load the 2 dataframes

sales_data <- dataImport(input_path = argument_parser$input_data,
                         file_name = argument_parser$sales_file)

product_data <- dataImport(input_path = argument_parser$input_data,
                           file_name = argument_parser$product_file)

# BASIC SUMMARIZATION -----------------------------------------------------------------

summarized_index_counts <- product_data %>%
  group_by(index_group_name) %>%
  summarise(index_count = n()) %>%
  arrange(index_count)

summarized_deparment_counts <- product_data %>%
  group_by(department_name) %>%
  summarise(department_count = n()) %>%
  arrange(department_count)

summarized_product_code_counts <- product_data %>%
  group_by(product_code) %>%
  summarise(product_count = n()) %>%
  arrange(product_count)

summarized_product_type_counts <- product_data %>%
  group_by(product_type_name) %>%
  summarise(product_type_counts = n())


# TEMPORAL AUGMENTATION AND FEATURE ENGINEERING-----------------------------------------------------------------

sales_data <- sales_data %>%
  mutate(article = as.numeric(str_sub(
    variant, start = 1, end = 9
  ))) %>%
  mutate(product_code = as.numeric(str_sub(
    variant, start = 1, end = 6
  ))) %>%
  mutate(net_amount=ifelse(purchases == 0, 0, net_amount), # removing meaningless NANs
         gross_amount=ifelse(purchases == 0, 0, gross_amount)) %>%  # removing meaningless NANs
  tk_augment_timeseries_signature(.date_var = date) %>%
  select(
    -c(
      index.num,
      diff,
      year,
      year.iso,
      half,
      quarter,
      qday,
      month,
      month.xts,
      month.lbl,
      hour,
      minute,
      second,
      hour12,
      am.pm,
      wday.xts,
      wday.lbl,
      week.iso,
      week2,
      week3,
      week4
    )
  ) %>%
  mutate(is_markdown = ifelse(mweek == 1, 0, 1)) %>% #MANUAL ONE HOT ENCODING
  mutate(unitary_net_amount = ifelse(is.na(net_amount), NA, net_amount/purchases)) %>% 
  mutate(unitary_gross_amount = ifelse(is.na(net_amount), NA, net_amount/purchases)) %>% 
  mutate(discount = ifelse(purchases != 0, (1-(net_amount/gross_amount))*100, 0))



sales_data_joined <- sales_data %>% left_join(product_data)

na_isolation <- sales_data_joined %>% 
  filter(is.na(net_amount))

missing_variants_product_codes <- na_isolation$product_code %>% unique()

missing_variants_product_codes_data <- sales_data_joined %>% 
  filter(product_code %in% missing_products)

a <- missing_variants_product_codes_data %>% 
  group_by(product_type_name, is_markdown, week) %>% 
  summarise(
    median_unitary_net_amount = median(unitary_net_amount, na.rm = TRUE),
    median_gross_amount = median(unitary_gross_amount, na.rm = TRUE),
    median_discount = median(discount, na.rm = TRUE)
  )


sales_data_joined_pivotted <- sales_data_joined %>%
  pivot_longer(
    cols = c(net_amount, gross_amount, purchases),
    names_to = "variable",
    values_to = "value"
  )

sales_tsibble <- sales_data_joined  %>% 
  as_tsibble(key = c(index_group_name, department_name, 
                     product_type_name, product_code, article, variant), index = date) 

sales_tsibble_by_product_type <- sales_tsibble %>% 
  group_by(product_type_name) %>%
  summarise(net_amount = sum(net_amount),
            purchases = sum(purchases))

sales_tsibble_by_index_group <- sales_tsibble %>% 
  group_by(index_group_name) %>%
  summarise(net_amount = sum(net_amount),
            purchases = sum(purchases))

gap_count_sales <- sales_tsibble %>% count_gaps(.full = TRUE)

gap_count_sales_by_index_group <- sales_tsibble_by_index_group %>% count_gaps(.full = TRUE)


gap_count_sales_by_product_type <- sales_tsibble_by_product_type %>% count_gaps(.full = TRUE)

# EDA -----------------------------------------------------------------

ggplot(gap_count_sales_by_product_type,
       aes(x = product_type_name, colour = product_type_name)) +
  geom_linerange(aes(ymin = .from, ymax = .to)) +
  geom_point(aes(y = .from)) +
  geom_point(aes(y = .to)) +
  coord_flip() +
  theme(legend.position = "right")



a <- ggplot(sales_tsibble_by_product_type, aes(date, net_amount)) +
  geom_line(aes(colour = product_type_name)) +
  geom_vline(
    xintercept = as.numeric(as.Date("2017-10-09")),
    linetype = 4,
    colour = "black"
  ) +
  geom_text(
    aes(
      x = as.Date("2017-10-09"),
      label = "Markdown Starts",
      y = 20000
    ),
    colour = "Red",
    angle = 90
  )
b <- ggplot(sales_tsibble_by_product_type, aes(date, purchases)) + 
  geom_line(aes(colour = product_type_name)) +
  geom_vline(
    xintercept = as.numeric(as.Date("2017-10-09")),
    linetype = 4,
    colour = "black"
  ) +
  geom_text(
    aes(
      x = as.Date("2017-10-09"),
      label = "Markdown Starts",
      y = 1000
    ),
    colour = "Red",
    angle = 90
    
  )

grid_arrange_shared_legend(a,
                           b,
                           nrow = 2,
                           ncol = 1,
                           position = "right")


