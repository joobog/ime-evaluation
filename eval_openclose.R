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
dbdata = dbGetQuery(connection,'select *, (nn*ppn) as procs from p ')
dbdata[,"blocksize"] = dbdata$x * dbdata$y * dbdata$z * 4


summary(dbdata)

nn_lab <- sprintf(fmt="NN %d", unique(dbdata$nn))
names(nn_lab) <- unique(dbdata$nn)
ppn_lab <- sprintf(fmt="PPN %d", unique(dbdata$ppn))
names(ppn_lab) <- unique(dbdata$ppn)
breaks <- c(unique(dbdata$blocksize))


fig_w = 4
fig_h = 4

w = c(4, 6, 4) 
h = c(4, 4, 4) 
event = c("paper", "isc-pres", "poster")
dims_list = data.frame(h, w, event)       # df is a data frame




fss = unique(dbdata$fs) # lustre, ime, fuse
for (fs in fss) {
data1 = dbdata[fs == dbdata$fs, ]
ifaces = unique(data1$iface)

for (iface in ifaces) {  # mpio, ime, posix
data2 = data1[iface == data1$iface, ]
apps = unique(data2$app)

for (app in apps) { # benchtool, ior
data = data2[app == data2$app, ]


	#ggplot(data=data, aes(x=nn, y=ropen, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
	ggplot(data=data, aes(x=nn, y=ropen, color=ppn)) +
		geom_point() +
		xlab("Nodes") +
		ylab("Duration in sec") +
		theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		theme(legend.position="right") +
		#scale_y_log10() +
		scale_x_continuous(breaks = c(unique(data$nn))) +
    geom_smooth(data=data[data$ppn==8,]) + 
    geom_smooth(data=data[data$ppn==6,]) + 
    geom_smooth(data=data[data$ppn==4,]) + 
    geom_smooth(data=data[data$ppn==2,]) + 
    geom_smooth(data=data[data$ppn==1,]) + 
    scale_colour_gradientn(colours = rainbow(7))   # + geom_abline(slope=0.1089, intercept=0.1315)
	filename_eps = sprintf("%s/performance_%s_%s_%s_%s.eps", folder_out, app, fs, iface, "readopen")
	ggsave(filename_eps, width = 6, height = 4)
	system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))

	ggplot(data=data, aes(x=nn, y=wopen, color=ppn)) +
		geom_point() +
		xlab("Nodes") +
		ylab("Duration in sec") +
		theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		theme(legend.position="right") +
		#scale_y_log10() +
		scale_x_continuous(breaks = c(unique(data$nn))) +
    geom_smooth(data=data[data$ppn==8,]) + 
    geom_smooth(data=data[data$ppn==6,]) + 
    geom_smooth(data=data[data$ppn==4,]) + 
    geom_smooth(data=data[data$ppn==2,]) + 
    geom_smooth(data=data[data$ppn==1,]) + 
    scale_colour_gradientn(colours = rainbow(7))   # + geom_abline(slope=0.1089, intercept=0.1315)
	filename_eps = sprintf("%s/performance_%s_%s_%s_%s.eps", folder_out, app, fs, iface, "writeopen")
	ggsave(filename_eps, width = 6, height = 4)
	system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))



}}}
