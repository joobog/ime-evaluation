#!/usr/bin/env Rscript

library(sqldf)
library(plyr)
library(plot3D)
library(ggplot2)


args = commandArgs(trailingOnly=TRUE)
print(args)
if (2 != length(args)) {
	print("Requires 2 parameters)")
	q()
}

file_db = args[1]
folder_out = args[2]
print(file_db)

make_facet_label <- function(variable, value){
  return(paste0(value, " KiB"))
}


#connection = dbConnect(SQLite(), dbname='results.ddnime.db')
print(file_db)
connection = dbConnect(SQLite(), dbname=file_db)

#dbdata = dbGetQuery(connection,'select mnt, siox, avg(duration) as ad, app, procs, blocksize from p group by mnt, siox, procs, blocksize, app')
#dbdata = dbGetQuery(connection,'select *  from p where tag=="mpio-individual"')
#dbdata = dbGetQuery(connection,'select *, (x*y*z) as blocksize from p where count=8')
#dbdata = dbGetQuery(connection,'select * from p where count<5')
dbdata = dbGetQuery(connection,'select * from p')
dbdata[,"blocksize"] = dbdata$tsize


summary(dbdata)

nn_lab <- sprintf(fmt="NN=%d", unique(dbdata$nn))
names(nn_lab) <- unique(dbdata$nn)
ppn_lab <- sprintf(fmt="PPN=%d", unique(dbdata$ppn))
names(ppn_lab) <- unique(dbdata$ppn)
breaks <- c(unique(dbdata$blocksize))




	#p = ggplot(data=dbdata, aes(x=nn, y=rio, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
	p = ggplot(data=dbdata) +
		#ggtitle("Read") +
		#facet_grid(ppn ~ ., labeller = labeller(nn = as_labeller(nn_lab), ppn = as_labeller(ppn_lab))) +
		#xlab("Nodes") +
		#ylab("Performance in MiB/s") +
		#theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		#theme(legend.position="bottom") +
		scale_x_continuous(breaks = c(60, 120)) +
		#scale_x_log10(breaks = c(unique(data$nn))) +
		scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000'), breaks=sort(unique(dbdata$blocksize)/1024)) +
		#stat_summary(fun.y="median", geom="line", aes(group=factor(blocksize))) +
		#stat_summary(fun.y="mean", geom="line", aes(group=factor(blocksize))) +
		#geom_boxplot()
		geom_histogram(binwidth=1, aes(wio, fill="red")) + 
		geom_histogram(binwidth=1, aes(rio, fill="blue"))
		#geom_density(aes(wio, color="blue")) + 
		#geom_density(aes(rio, color="red"))
		#geom_freqpoly(binwidth=4)


	filename_eps = sprintf("%s/runtime.eps", folder_out)
	filename_png = sprintf("%s/runtime.png", folder_out)

	ggsave(filename_png, width = 10, height = 3)
	ggsave(filename_eps, width = 10, height = 3)
	#system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))

