#!/usr/bin/env Rscript

library(sqldf)
library(plyr)
library(plot3D)
library(ggplot2)
library(gtools)


args = commandArgs(trailingOnly=TRUE)
#print(args)
#if (2 != length(args)) {
	#print("Requires 2 parameters)")
	#q()
#}

#file_db = args[1]
#folder_out = args[2]

file_db_random = 'results_random.db'
file_db_sequential = 'results_sequential.db'
folder_out = 'plot_read_write'

#file_db = file_db_sequential
file_db = file_db_random

make_facet_label <- function(variable, value){
  return(paste0(value, " KiB"))
}


#connection = dbConnect(SQLite(), dbname='results.ddnime.db')
print(file_db)
connection = dbConnect(SQLite(), dbname=file_db)

dbdata = dbGetQuery(connection,'select * from p')
dbdata[,"blocksize"] = dbdata$x * dbdata$y * dbdata$z * 4

dbdata$nn_lab <- sprintf(fmt="NN=%d; PPN=1-10", dbdata$nn)
dbdata$nn_lab_f <- factor(dbdata$nn_lab, sprintf(fmt="NN=%d; PPN=1-10", sort(unique(dbdata$nn))))
print(dbdata$nn_lab)
#names(nn_lab) <- unique(dbdata$nn)

summary(dbdata)

fss = unique(dbdata$fs)
for (fs in fss) {
data = dbdata[fs == dbdata$fs, ]

ggplot(data=data, aes(x=read, y=write, colour=as.factor(blocksize/1024), group=blocksize), ymin=0, xmin=0) +
	#ggtitle("Write") +
	facet_grid(. ~ nn_lab_f) +
	facet_wrap(~ nn_lab_f) +
	xlab("Read Performance in MiB/s") +
	ylab("Write Performance in MiB/s") +
	#theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
	theme(legend.position="bottom") +
	theme(aspect.ratio=1) +
	scale_y_log10() +
	scale_x_log10() +
	scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000','#999999','#E69F00', '#56B4E9', '#000000','#999999','#E69F00', '#56B4E9', '#000000' )) +
	geom_point()

	filename = sprintf("%s/performance_overview_rnd_%s", folder_out, fs)
	filename_eps = sprintf("%s.eps", filename)
	filename_png = sprintf("%s.png", filename)
	filename_pdf = sprintf("%s.pdf", filename)
	#ggsave(filename_eps, width = 12, height = 6)
	#ggsave(filename_eps, dpi=1000)
	ggsave(filename_eps, width = 16)
	ggsave(filename_png, dpi=300)
	system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))
	system(sprintf("pdfcrop %s %s", filename_pdf, filename_pdf))
}
