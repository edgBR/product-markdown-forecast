library(ggplot2)
library(gridExtra)
library(grid)

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
  grid.newpage()
  grid.draw(combined)
  
}


grid_arrange_shared_legend(a,b, nrow=2, ncol = 1, position = "right")


a<-ggplot(sales_tsibble_normal, aes(date, net_amount))+
  geom_line(aes(colour=product_type_name))+
  geom_vline(xintercept = as.numeric(as.Date("2017-10-09")), 
             linetype=4, colour="black") +
  geom_text(aes(x=as.Date("2017-10-09"), label="Markdown Starts", y=50000), 
            colour="Red", angle=90)
b<-ggplot(sales_tsibble_normal, aes(date, purchases))+geom_line(aes(colour=product_type_name))