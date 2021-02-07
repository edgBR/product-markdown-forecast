# IMPORTS -----------------------------------------------------------------

library(logger)
library(optparse)
library(timetk)

set.seed(2021)
log_level(level = "INFO")

source("code/R/get_data.R")
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
    default = 'output/data',
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


argument_parser <-
  parse_args(OptionParser(option_list = option_list))



# DATA LOADING ------------------------------------------------------------


### We load the 2 dataframes

sales_data <- data_import(input_path = argument_parser$input_data,
                          file_name = argument_parser$sales_file)

product_data <- data_import(input_path = argument_parser$input_data,
                            file_name = argument_parser$product_file)

# BASIC SUMMARIZATION -----------------------------------------------------------------

### we create multiple summary dataframes to understand the product hierarchy in terms of counts

summary_list <- hierarchical_product_summarizer(product_data)


# TEMPORAL AND MANUAL FEATURES AND AUXILIAR DATA FRAMES FOR EDA ---------------------------

### We replace the NANs of gross and net amount when purchases are 0
### we create a binary variable to represent the markdown period
### we also create temporal features and calculated the discount
### that every variant has

sales_data_processed <- sales_processor(sales_data)

sales_data_joined <- sales_data_processed %>%
  left_join(product_data) %>%
  group_by(index_group_name,
           department_name,
           product_type_name,
           product_code,
           variant,
           date)

product_type_name <- sales_data_joined %>% 
  ungroup() %>% 
  select(product_type_name) %>% 
  distinct() %>% 
  arrange() %>% 
  mutate(product_type_name_encoded = row_number())

index_group_name <- sales_data_joined %>%  
  ungroup() %>% 
  select(index_group_name) %>% 
  distinct() %>% 
  arrange() %>% 
  mutate(index_group_name_encoded = row_number())


department_name <- sales_data_joined %>%  
  ungroup() %>% 
  select(department_name) %>% 
  distinct() %>% 
  arrange() %>% 
  mutate(department_name_encoded = row_number())

section_name <- sales_data_joined %>%  
  ungroup() %>%  
  select(section_name) %>% 
  distinct() %>% 
  arrange() %>% 
  mutate(section_name_encoded = row_number())

sales_data_joined_markdown_effect <- sales_data_joined %>%
  group_by(product_type_name, is_markdown) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )

### We create the uplift variable according to the suggestion of the instructions
###  Important comment: there is no guarantee that the discounts are constant over time

sales_data_joined_uplift <- sales_data_joined %>%
  group_by(product_type_name, mweek) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  ) %>%
  mutate(
    uplift1 = sum_of_purchases / lag(sum_of_purchases, n = 1),
    # lag with respect to week without markdown
    uplift2 = sum_of_purchases / lag(sum_of_purchases, n = 2) # lag with respect first week of markdown
  )



sales_data_summarized <- sales_data_joined %>%
  group_by(
    index_group_name,
    department_name,
    product_type_name,
    product_code,
    variant,
    week,
    is_markdown
  ) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )



# TSIBBLE FORMAT AND GAP COUNTS-----------------------------------------------------------------

sales_tsibble <- sales_data_joined  %>% ungroup() %>%
  as_tsibble(
    key = c(
      index_group_name,
      department_name,
      product_type_name,
      product_code,
      article,
      variant
    ),
    index = date
  )

sales_tsibble_by_product_type <- sales_tsibble %>%
  group_by(product_type_name) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )


sales_tsibble_by_index_group <- sales_tsibble %>%
  group_by(index_group_name) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )


sales_tsibble_by_section_name <- sales_tsibble %>%
  group_by(section_name) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )


sales_tsibble_by_department_name <- sales_tsibble %>%
  group_by(department_name) %>%
  summarise(
    sum_of_purchases = sum(purchases, na.rm = TRUE),
    sum_of_net_amount = sum(net_amount, na.rm = TRUE),
    sum_of_gross_amount = sum(gross_amount, na.rm = TRUE)
  )

# GAP COUNTS-----------------------------------------------------------------

gap_count_sales_total <- sales_tsibble %>%
  count_gaps(.full = TRUE)

gap_count_sales_by_index_group <- sales_tsibble_by_index_group %>%
  count_gaps(.full = TRUE)


gap_count_sales_by_product_type <-
  sales_tsibble_by_product_type %>%
  count_gaps(.full = TRUE)

# EDA -----------------------------------------------------------------

## GAP PLOT

ggplot(
  gap_count_sales_by_product_type,
  aes(x = product_type_name, colour = product_type_name)
) +
  geom_linerange(aes(ymin = .from, ymax = .to)) +
  geom_point(aes(y = .from)) +
  geom_point(aes(y = .to)) +
  coord_flip() +
  theme(legend.position = "right")

## TEMPORAL EVLOUTION PLOTS


product_type_net_amount_plot <-
  ggplot(sales_tsibble_by_product_type, aes(date, sum_of_net_amount)) +
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
product_type_purchases_plot  <-
  ggplot(sales_tsibble_by_product_type, aes(date, sum_of_purchases)) +
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

product_type_temporal_evolution <-
  grid_arrange_shared_legend(
    product_type_net_amount_plot,
    product_type_purchases_plot,
    nrow = 2,
    ncol = 1,
    position = "right"
  )
grid_plot(product_type_temporal_evolution)


section_name_net_amount_plot <-
  ggplot(sales_tsibble_by_section_name, aes(date, sum_of_net_amount)) +
  geom_line(aes(colour = section_name)) +
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
section_name_purchases_plot  <-
  ggplot(sales_tsibble_by_section_name, aes(date, sum_of_purchases)) +
  geom_line(aes(colour = section_name)) +
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

section_name_temporal_evolution <-
  grid_arrange_shared_legend(
    section_name_net_amount_plot,
    section_name_purchases_plot,
    nrow = 2,
    ncol = 1,
    position = "right"
  )
grid_plot(section_name_temporal_evolution)

## Variable relationship

ggplot(sales_data_joined,
       aes(unitary_net_amount, purchases, colour = as.factor(is_markdown))) +
  geom_point() +
  facet_wrap(~ index_group_name)

ggplot(sales_data_joined,
       aes(net_amount, purchases, colour = as.factor(is_markdown))) +
  geom_point() +
  facet_wrap(~ index_group_name)

ggplot(sales_data_joined_uplift,
       aes(x = is_markdown, y = sum_of_purchases)) +
  geom_line(aes(colour = product_type_name)) +
  ggtitle("Effect of markdown in aggregated sales by product type name")

## Total sales

ggplot(
  sales_data_joined %>% group_by(product_type_name, index_group_name) %>%
    summarise(sum_of_purchases = sum(purchases, na.rm = TRUE)),
  aes(
    x = reorder(product_type_name,+sum_of_purchases),
    y = sum_of_purchases,
    fill = index_group_name
  )
) +
  geom_col() +
  coord_flip() +
  xlab("Total purchases") +
  ylab("Product Type Name")


ggplot(
  sales_data_joined %>% group_by(product_type_name, index_group_name, is_markdown) %>%
    summarise(sum_of_purchases = sum(purchases, na.rm = TRUE)),
  aes(
    x = reorder(product_type_name,+sum_of_purchases),
    y = sum_of_purchases,
    fill = index_group_name
  )
) +
  geom_col() +
  coord_flip() +
  facet_wrap(.~is_markdown) +
  xlab("Total purchases") +
  ylab("Product Type Name")

# NA ANALYSIS FOR NET AMOUNT-----------------------------------------------------------------

### We investigate the NANs in net amount as it seems a relevant feature in the EDA

na_isolation <- sales_data_joined %>%
  filter(is.na(net_amount))

missing_variants_product_codes <-
  na_isolation$product_code %>% unique()

missing_sales_data <- sales_data_joined %>%
  filter(product_code %in% missing_variants_product_codes)

missing_data_summary <- missing_sales_data %>%
  group_by(index_group_name,
           department_name,
           product_type_name,
           is_markdown,
           week) %>%
  summarise(
    median_unitary_net_amount = median(unitary_net_amount, na.rm = TRUE),
    median_gross_amount = median(unitary_gross_amount, na.rm = TRUE),
    median_discount = median(discount, na.rm = TRUE)
  )


# TIME SERIES INTERNAL FEATURES -----------------------------------------------------------------


sales_tsibble_training <- sales_tsibble %>%
  features(purchases, feat_stl)


pca_sales_tsibble_training <- sales_tsibble_training %>%
  select(-c(where(is.character))) %>%
  na.omit() %>%
  prcomp(scale = TRUE)

pca_analysis <- pca_sales_tsibble_training$x %>%
  as_tibble()

full_pca_analysis <-
  bind_cols(pca_analysis, sales_tsibble_training %>%
              na.omit())

ggplot(full_pca_analysis,
       aes(PC1, PC2)) +
  geom_point(aes(colour = index_group_name))
## PCA plot seems not conclusive


# GENERATING FINAL DATASET  -------------

sales_data_joined_uplift_week1 <-
  left_join(sales_data_joined_uplift %>%
              select(-c(uplift2)), sales_data_joined) %>%
  ungroup() %>% 
  inner_join(., product_type_name) %>% 
  inner_join(., index_group_name) %>% 
  inner_join(., department_name) %>% 
  inner_join(., section_name) %>% 
  filter(mweek == 2) %>%
  select(-c(product_type_name, index_group_name, department_name, section_name)) %>% 
  drop_na() #removing first week as uplift is NAN

sales_data_joined_uplift_week2 <-
  left_join(sales_data_joined_uplift, sales_data_joined) %>%
  ungroup() %>% 
  inner_join(., product_type_name) %>% 
  inner_join(., index_group_name) %>% 
  inner_join(., department_name) %>% 
  inner_join(., section_name) %>% 
  select(-c(product_type_name, index_group_name, department_name, section_name)) %>% 
  filter(mweek != 1) %>%  #removing first week as uplift is NA %>% 
  drop_na()

vroom_write(sales_data_joined_uplift_week1, 
            path = paste(argument_parser$output_data, 
                         "sales_uplift_week1.csv", sep="/"),
            delim = ","
            )

vroom_write(sales_data_joined_uplift_week2, 
            path = paste(argument_parser$output_data, 
                         "sales_uplift_week2.csv", sep="/"),
            delim = ","
)



# FEATURE IMPORTANCE PLOT -------------

uplift1_feat <- data_import(argument_parser$output_data,
                            file_name = 'feature_importance_xgboost_uplift1.csv') %>% 
  t() %>% 
  as.data.frame() %>% 
  tibble::rownames_to_column(., "feature_name") %>% 
  filter(V1!=0)


uplift2_feat <- data_import(argument_parser$output_data,
                            file_name = 'feature_importance_xgboost_uplift2.csv') %>% 
  t() %>% 
  as.data.frame() %>% 
  tibble::rownames_to_column(., "feature_name") %>% 
  filter(V1!=0)

a<-ggplot(uplift1_feat, aes(x=V1, y=reorder(feature_name, -V1))) + 
  geom_col() + 
  xlab("Feature Importance") +
  ylab("Feature Name") + 
  ggtitle("XGBoost feature importance plot for 1st markdown week")


b<-ggplot(uplift2_feat, aes(x=V1, y=reorder(feature_name, -V1))) + 
  geom_col() + 
  xlab("Feature Importance") +
  ylab("Feature Name") + 
  ggtitle("XGBoost feature importance plot for 2st markdown week")

grid.arrange(a,b)