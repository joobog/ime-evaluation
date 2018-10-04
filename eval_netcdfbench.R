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

file_db = 'results_benchtool.db'
folder_out = 'plot_coll_chunked'
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
dbdata = dbGetQuery(connection,'select * from p where nn==10 and ppn=8')
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


for (scale in c('log', 'linear')) {

fss = unique(dbdata$fs)
for (fs in fss) {
data1 = dbdata[fs == dbdata$fs, ] # ime, lustre, fuse
ifaces = unique(data1$iface)

for (iface in ifaces) {
data2 = data1[iface == data1$iface, ] # posix, mpio, ime
apps = unique(data2$app)

for (app in apps) {
data3 = data2[app == data2$app, ] # ior, benchtool
filleds = unique(data3$filled)

for (filled in filleds) {
data4 = data3[filled == data2$filled, ]
unlimiteds = unique(data4$unlimited)

for (unlimited in unlimiteds) {
data = data4[unlimited == data3$unlimited, ]

	dat_write <- data.frame(chunked=data$chunked, type=data$type, perf=data$write, blocksize=data$blocksize, access="write")
	dat_read <-  data.frame(chunked=data$chunked, type=data$type, perf=data$read, blocksize=data$blocksize, access="read")

	dat <- rbind(dat_write, dat_read)
	#dat$lab <- paste0(dat$blocksize/1024, "/", dat$access)
	dat$lab <- paste0(dat$blocksize/1024)
	dat$lab_type <- data$type;
	dat$lab_type[dat$lab_type == "coll"] = "Collective"
	dat$lab_type[dat$lab_type == "ind"] = "Independent"
	dat$lab_chunked <- data$chunked;
	dat$lab_chunked[dat$lab_chunked == "auto"] = "Chunking"
	dat$lab_chunked[dat$lab_chunked == "notset"] = "No chunking"
	print(summary(dat))


	print(mixedsort(unique(dat$lab)))


	p <- ggplot(data=dat, aes(x=lab, y=perf, colour=as.factor(blocksize/1024), group=interaction(access, blocksize)), ymin=0) +
		#ggtitle("Write") +
		#facet_grid(ppn ~ ., labeller = labeller(nn = as_labeller(nn_lab), ppn = as_labeller(ppn_lab))) +
		facet_grid(. ~ lab_type + lab_chunked + access) +
		xlab("Blocksizes in KiB / Access") +
		ylab("Performance in MiB/s") +
		theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		theme(legend.position="bottom") +
		#ylim(0, 100000) +
		#scale_x_continuous(breaks = c(unique(data$nn))) +
		#scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000'), breaks=sort(unique(data$blocksize)/1024)) +
		scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000', '#999999','#E69F00', '#56B4E9', '#000000'), breaks=mixedsort(unique(dat$lab))) +
		scale_fill_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000', '#999999','#E69F00', '#56B4E9', '#000000'), breaks=mixedsort(unique(dat$lab))) +
		#stat_summary(fun.y="median", geom="line", aes(group=factor(blocksize))) +
		#stat_summary(fun.y="max", geom="line", aes(group=factor(blocksize))) +
		geom_boxplot()
		#geom_bar()
		#geom_point()

		if ('log' == scale) {
			p = p + scale_y_log10(breaks=c(100, 1000, 10000, 40000))
		}
		{
			p = p + scale_x_discrete(breaks=mixedsort(unique(dat$lab)), limits=mixedsort(unique(dat$lab)))
		}


	filename_eps = sprintf("%s/performance_%s_FS:%s_IFACE:%s_FILLED_%s_LIM:%s_SCALE:%s.eps", folder_out, app, fs, iface, filled, unlimited, scale)
	filename_png = sprintf("%s/performance_%s_FS:%s_IFACE:%s_FILLED_%s_LIM:%s_SCALE:%s.png", folder_out, app, fs, iface, filled, unlimited, scale)
	ggsave(filename_eps, width = 8, height = 8)
	ggsave(filename_png, width = 8, height = 8)
	system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))

}}}}}}
#}}
