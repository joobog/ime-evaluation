#!/usr/bin/env Rscript

library(sqldf)
library(plyr)
library(plot3D)
library(ggplot2)
require(gridExtra)


theme_set(theme_gray(base_size = 25))

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
#dbdata = dbGetQuery(connection,'select * from p where iface="mpio" and (ppn==1 or ppn=4 or ppn=8)')
dbdata = dbGetQuery(connection,'select * from p where (ppn==1 or ppn=4 or ppn=8)')
dbdata[,"blocksize"] = dbdata$x * dbdata$y * dbdata$z * 4


#summary(dbdata)

nn_lab <- sprintf(fmt="NN=%d", unique(dbdata$nn))
names(nn_lab) <- unique(dbdata$nn)

ppn_lab <- sprintf(fmt="PPN=%d", unique(dbdata$ppn))
names(ppn_lab) <- unique(dbdata$ppn)

breaks <- c(unique(dbdata$blocksize))


#fig_w = 4
#fig_h = 4

#w = c(4, 6, 4) 
#h = c(4, 4, 4) 
#event = c("paper", "isc-pres", "poster")
#dims_list = data.frame(h, w, event)       # df is a data frame



for (scale in c('log', 'linear')) {
fss = unique(dbdata$fs)
for (fs in fss) {
data1 = dbdata[fs == dbdata$fs, ]
#apps = unique(data1$app)
ifaces = unique(data1$iface)

for (iface in ifaces) {
data2 = data1[iface == data1$iface, ]
apps = unique(data2$app)

for (app in apps) {
data3 = data2[app == data2$app, ]
types = unique(data3$type)

for (type in types) {
data4 = data3[type == data3$type, ]
chunkeds = unique(data4$chunked)

for (chunked in chunkeds) {
data5 = data4[chunked == data4$chunked, ]
filleds = unique(data4$filled)

for (filled in filleds) {
data6 = data5[filled == data5$filled, ]
unlimiteds = unique(data5$unlimited)

for (unlimited in unlimiteds) {
data = data6[unlimited == data5$unlimited, ]

	dat_write <- data.frame(real_perf=data$fsize/data$wio/1024^2, nn=data$nn, ppn=data$ppn, iface=data$iface, chunked=data$chunked, type=data$type, perf=data$write, blocksize=data$blocksize, access="write", tio="wio", stringsAsFactors = FALSE)
	dat_read <- data.frame(real_perf=data$fsize/data$rio/1024^2, nn=data$nn, ppn=data$ppn, iface=data$iface, chunked=data$chunked, type=data$type, perf=data$read, blocksize=data$blocksize, access="read", tio="rio", stringsAsFactors = FALSE)
	dat <- rbind(dat_write, dat_read)


	dat$lab_ppn <- paste0("PPN=", dat$ppn)

	dat$lab_iface <- dat$iface
	dat$lab_iface[dat$lab_iface == "posix"] = "POSIX"
	dat$lab_iface[dat$lab_iface == "mpio"] = "MPIIO"
	dat$lab_iface[dat$lab_iface == "ime"] = "IME"
	
	dat$lab_access <- dat$access
	dat$lab_access[dat$lab_access == "write"] = "Write"
	dat$lab_access[dat$lab_access == "read"] = "Read"


	print(summary(dat))
	#print(dat[0:10])


#library(ggplot2)
#p = qplot(1, 1)
#grid.arrange(p, p, respect=TRUE) # both viewports are square
#grid.arrange(p, p, respect=TRUE, heights=c(1,2)) # relative heights

#p1 = p + theme(aspect.ratio=3)
#grid.arrange(p,p1, respect=TRUE) # one is square, the other thinner


for (print_legend in c("yes", "no")) {

	#p <- ggplot(data=dat, aes(x=nn, y=perf, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
	p <- ggplot(data=dat, aes(x=nn, y=real_perf, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
		#ggtitle("Write") +
		#facet_grid(ppn ~ ., labeller = labeller(nn = as_labeller(lab), ppn = as_labeller(lab))) +
		#facet_grid(lab_ppn ~ lab_iface + lab_access) +
		facet_grid(lab_ppn ~ lab_access) +
		xlab("Nodes") +
		ylab("Performance in MiB/s") +
		theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		#scale_y_log10() +
		scale_x_continuous(breaks = c(unique(data$nn))) +
		scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000'), breaks=sort(unique(data$blocksize)/1024)) +
		#stat_summary(fun.y="median", geom="line", aes(group=factor(blocksize))) +
		stat_summary(fun.y="max", geom="line", aes(group=factor(blocksize))) +
		#coord_fixed(ratio=1) +
		theme(aspect.ratio=1) +
		theme(plot.margin=grid::unit(c(0,0,0,0), "mm")) +
		#geom_boxplot()
		geom_point()


#grid.arrange(p, p, respect=TRUE) # both viewports are square


#p1 = p + theme(aspect.ratio=3)
#grid.arrange(p,p1, respect=TRUE) # one is square, the other thinner

#p = qplot(1, 1)
#grid.arrange(p, p, respect=TRUE) # both viewports are square
#grid.arrange(p, p, respect=TRUE, heights=c(1,2)) # relative heights

	if(fs=="lustre") {
		print("Lustre limit")
		p = p + ylim(0, 20000)
	}
	#if(fs=="fuse") {
	#p = p + theme(legend.position="bottom")
	#}
	if(print_legend=="yes") {
		p = p + theme(legend.position="bottom")
	}
	else {
		p = p + theme(legend.position="none")
	}

	if ('log' == scale) {
		p = p + scale_y_log10()
		p = p + scale_x_log10(breaks = c(unique(data$nn)))
		#p = p + scale_y_log10(breaks=c(100, 1000, 10000, 40000))
	}
	{
		#p = p + scale_x_discrete(breaks=mixedsort(unique(dat$lab)), limits=mixedsort(unique(dat$lab)))
	}

	filename_eps_base = sprintf("%s/performance_%s_%s_%s_%s_CHUNK:%s_FILL:%s_LIM:%s_legend:%s_SCALE:%s", folder_out, app, fs, iface, type, chunked, filled, unlimited, print_legend, scale)
	filenmae_eps=""

	if(fs=="ime") {
		filename = sprintf("%s_size:%dx%d", filename_eps_base, 6, 8)
		filename_eps = sprintf("%s.eps", filename)
		filename_png = sprintf("%s.png", filename)
		filename_pdf = sprintf("%s.pdf", filename)
		ggsave(filename_eps, width = 6, height = 6)
		ggsave(filename_png, dpi=300)
		system(sprintf("epstopdf %s", filename_eps))
		system(sprintf("rm %s", filename_eps))
		system(sprintf("pdfcrop %s %s", filename_pdf, filename_pdf))
	}

	#filename = sprintf("%s_size:%dx%d", filename_eps_base, 12, 8)
	filename = sprintf("%s_size:%dx%d", filename_eps_base, 9, 6)
	filename_eps = sprintf("%s.eps", filename)
	filename_png = sprintf("%s.png", filename)
	filename_pdf = sprintf("%s.pdf", filename)
	#ggsave(filename_eps, width = 12, height = 6)
	ggsave(filename_eps, dpi=300)
	ggsave(filename_png, dpi=300)
	system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))
	system(sprintf("pdfcrop %s %s", filename_pdf, filename_pdf))
} # for legend

}}}}}}}
} # scale
