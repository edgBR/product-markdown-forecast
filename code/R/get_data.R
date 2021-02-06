library(vroom)



data_import <- function(input_path, file_name) {
  data_out <- tryCatch(
    vroom(file = paste(input_path, file_name, sep="/")), 
    error = function(e) {e}, 
    warning = function(w) {w}
    )
  if(inherits(data_out, "error")){
    log_error(data_out$message)
  } else if(inherits(data_out, "warning")){
    log_warn(data_out$message)
  } else {
    log_info("Reading {file_name} was successful")
  }
  return(data_out %>% rename_all(tolower)) ## forcing lowercase
}
