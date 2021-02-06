library(logger)
library(optparse)


set.seed(2021)
log_level(level = "INFO")


source("code/R/get_data.R")
source("code/R/tsa.R")
source("code/R/process_data.R")
source("code/R/plotting_utils.R")

### Note, change defaults by environment variables that can be injected to the code if running
### as a container somewhere


option_list <- list( 
  make_option(c("-i", "--input_data"), default='input/data',
              help="Default input data directory[default]",
              metavar="character"),
  make_option(c("-s", "--sales_file"), default="sales_master.csv",
              help="Name of the sales file",
              metavar="character"),
  make_option(c("-p", "--product_file"), default="product_table.csv",
              help="Name of the sales file",
              metavar="character"),
  make_option(c("-o", "--output_data"), default='input/output',
              help="Default output data directory[default]",
              metavar="character"),
  make_option(c("-m", "--model"), default='models/',
              help="Model directory",
              metavar="character")
)


# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults


argument_parser <- parse_args(OptionParser(option_list=option_list))


### We load the 2 dataframes

sales_data <- dataImport(input_path = argument_parser$input_data,
                         file_name = argument_parser$sales_file)

product_data <- dataImport(input_path = argument_parser$input_data,
                           file_name = argument_parser$product_file)

summarized_product_code_amounts <- product_data %>% 
  group_by(product_code) %>% 
  summarise(product_count=n()) %>% 
  arrange(product_count)

product_type_counts <- product_data %>% 
  group_by(product_type_name) %>% 
  summarise(product_type_counts=n())

sales_data <- sales_data %>% 
  mutate(article=as.numeric(str_sub(variant, start = 1, end = 9))) %>% 
  mutate(product=as.numeric(str_sub(variant, start = 1, end = 6)))

sales_data_joined <- sales_data %>% left_join(product_data)

sales_tsibble_normal <- sales_data_joined %>% 
  as_tsibble(key=c(variant), index = date) %>% 
  group_by(product_type_name) %>% 
  summarise(
    net_amount=sum(net_amount),
    purchases=sum(purchases)
    )

sales_tsibble_cumsum <- sales_data_joined  %>% 
  group_by(product_type_name) %>% 
  arrange(date) %>% 
  summarise(
    cumulative_net_amount=cumsum(net_amount, na.rm=try),
    cumulative_purchases=cumsum(purchases),
    ) %>% 
  as_tsibble(key=c(product_type_name), index = date)


gap_count <- sales_tsibble %>% count_gaps(.full=TRUE)

ggplot(gap_count, aes(x = product_type_name, colour = product_type_name)) +
  geom_linerange(aes(ymin = .from, ymax = .to)) +
  geom_point(aes(y = .from)) +
  geom_point(aes(y = .to)) +
  coord_flip() +
  theme(legend.position = "right")
