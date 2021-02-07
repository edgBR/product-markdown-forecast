library(ggplot2)
library(gridExtra)
library(grid)
library(GGally)

grid_arrange_shared_legend <- function(..., nrow = 1, ncol = length(list(...)), position = c("bottom", "right")) {
  
  plots <- list(...)
  position <- match.arg(position)
  g <- ggplotGrob(plots[[1]] + theme(legend.position = position))$grobs
  legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
  lheight <- sum(legend$height)
  lwidth <- sum(legend$width)
  gl <- lapply(plots, function(x) x + theme(legend.position = "none"))
  gl <- c(gl, nrow = nrow, ncol = ncol)
  
  combined <- switch(position,
                     "bottom" = arrangeGrob(do.call(arrangeGrob, gl),
                                            legend,
                                            ncol = 1,
                                            heights = unit.c(unit(1, "npc") - lheight, lheight)),
                     "right" = arrangeGrob(do.call(arrangeGrob, gl),
                                           legend,
                                           ncol = 2,
                                           widths = unit.c(unit(1, "npc") - lwidth, lwidth)))

  
}

grid_plot <- function(plot_in) {
  grid.newpage()
  grid.draw(plot_in)
}
# 
# 
# individual_temporal_plot <- function(df_in, x_var, y_var, colour_var, markdown_start) {
#   plot <- tryCatch({
#     ggplot(df_in, aes_(x = ~x_var, y = ~y_var) +
#       geom_line(aes(colour = colour_var))) +
#       geom_vline(
#         xintercept = as.numeric(as.Date(markdown_start)),
#         linetype = 4,
#         colour = "black"
#       ) +
#       geom_text(
#         aes(
#           x = as.Date(markdown_start),
#           label = "Markdown Starts",
#           y = 20000
#         ),
#         colour = "Red",
#         angle = 90
#       )
#   },
#   error = function(e) {
#     e
#   },
#   warning = function(w) {
#     w
#   })
#   if (inherits(plot, "error")) {
#     log_error(plot$message)
#   } else if (inherits(plot, "warning")) {
#     log_warn(plot$message)
#   } else {
#     log_info("Individual plot was successful")
#   }
#   return(plot)
# }
