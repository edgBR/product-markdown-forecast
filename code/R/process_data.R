library(stringr)
library(dplyr)
library(tidyr)
library(tsibble)
library(feasts)

hierarchical_summarizer <- function(df_in, name_vector) {
  list_df <- tryCatch({
    list(
      summarized_index_counts <- df_in %>%
        group_by(index_group_name) %>%
        summarise(index_count = n()) %>%
        arrange(index_count),
      summarized_deparment_counts <- df_in %>%
        group_by(department_name) %>%
        summarise(department_count = n()) %>%
        arrange(department_count),
      summarized_product_code_counts <- df_in %>%
        group_by(product_code) %>%
        summarise(product_count = n()) %>%
        arrange(product_count),
      summarized_product_type_counts <- df_in %>%
        group_by(product_type_name) %>%
        summarise(product_type_counts = n())
    )
  },
  error = function(e) {
    e
  },
  warning = function(w) {
    w
  })
  
  if (inherits(list_df, "error")) {
    log_error(list_df$message)
  } else if (inherits(list_df, "warning")) {
    log_warn(list_df$message)
  } else {
    log_info("Summarization was successful")
  }
  
  return(list_df)
}


sales_processor <- function(df_in) {
  df_out <- tryCatch({
    df_in %>%
      mutate(article = as.numeric(str_sub(
        variant, start = 1, end = 9
      ))) %>%
      mutate(product_code = as.numeric(str_sub(
        variant, start = 1, end = 6
      ))) %>%
      mutate(
        net_amount = ifelse(purchases == 0, 0, net_amount),
        # removing meaningless NANs
        gross_amount = ifelse(purchases == 0, 0, gross_amount)
      ) %>%  # removing meaningless NANs
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
      mutate(is_markdown = ifelse(mweek == 1, 0, 1)) %>% # MANUAL ONE HOT ENCODING
      mutate(unitary_net_amount = ifelse(is.na(net_amount), NA, net_amount /
                                           purchases)) %>%
      mutate(unitary_gross_amount = ifelse(is.na(gross_amount), NA, gross_amount /
                                             purchases)) %>%
      mutate(discount = ifelse(purchases != 0, (1 - (
        net_amount / gross_amount
      )) * 100, 0))
  },
  error = function(e) {
    e
  },
  warning = function(w) {
    w
  })
  
  if (inherits(df_out, "error")) {
    log_error(df_out$message)
  } else if (inherits(df_out, "warning")) {
    log_warn(df_out$message)
  } else {
    log_info("Sales data processing was successful")
  }
  
  return(df_out)
}