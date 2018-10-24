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


fig_w = 4
fig_h = 4

w = c(4, 6, 4) 
h = c(4, 4, 4) 
event = c("paper", "isc-pres", "poster")
dims_list = data.frame(h, w, event)       # df is a data frame



for (scale in c("linear", "logarithmic")) {



fss = unique(dbdata$fs)
for (fs in fss) {
data1 = dbdata[fs == dbdata$fs, ]
apis = unique(data1$api)

print(fs)

for (api in apis) {
data2 = data1[api == data1$api, ]
apps = unique(data2$app)

print(api)

for (app in apps) {
data3 = data2[app == data2$app, ]
iotypes = unique(data3$iotype)

print(app)

for (iotype in iotypes) {
data = data3[iotype == data3$iotype, ]

print(iotype)

	p = ggplot(data=data, aes(x=nn, y=perf, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
		#ggtitle("Write") +
		facet_grid(ppn ~ accesstype + striping, labeller = labeller(nn = as_labeller(nn_lab), ppn = as_labeller(ppn_lab))) +
		xlab("Nodes") +
		ylab("Performance in MiB/s") +
		theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
		theme(legend.position="bottom") +
		#scale_x_continuous(breaks = c(unique(data$nn))) +
		scale_x_log10(breaks = c(unique(data$nn))) +
		scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000'), breaks=sort(unique(data$blocksize)/1024)) +
		#stat_summary(fun.y="median", geom="line", aes(group=factor(blocksize))) +
		stat_summary(fun.y="mean", geom="line", aes(group=factor(blocksize))) +
		#geom_boxplot()
		geom_point()

	if ( "logarithmic" == scale ) {
		p = p + scale_y_log10()
	}

	filename_eps = sprintf("%s/performance_%s_%s_%s_%s_%s_%s.eps", folder_out, app, fs, api, iotype, "write", scale)
	filename_png = sprintf("%s/performance_%s_%s_%s_%s_%s_%s.png", folder_out, app, fs, api, iotype, "write", scale)
	ggsave(filename_png, width = 6, height = 10)
	ggsave(filename_eps, width = 6, height = 10)
	#system(sprintf("epstopdf %s", filename_eps))
	system(sprintf("rm %s", filename_eps))

	#p = ggplot(data=data, aes(x=nn, y=read, colour=as.factor(blocksize/1024), group=blocksize), ymin=0) +
	#  #ggtitle("Read") +
	#  facet_grid(ppn ~ ., labeller = labeller(nn = as_labeller(nn_lab), ppn = as_labeller(ppn_lab))) +
	#  xlab("Nodes") +
	#  ylab("Performance in MiB/s") +
	#  theme(axis.text.x=element_text(angle=90, hjust=0.95, vjust=0.5)) +
	#  theme(legend.position="bottom") +
	#  #scale_x_continuous(breaks = c(unique(data$nn))) +
	#  scale_x_log10(breaks = c(unique(data$nn))) +
	#  scale_color_manual(name="Blocksize in KiB: ", values=c('#999999','#E69F00', '#56B4E9', '#000000'), breaks=sort(unique(data$blocksize)/1024)) +
	#  #stat_summary(fun.y="median", geom="line", aes(group=factor(blocksize))) +
	#  stat_summary(fun.y="mean", geom="line", aes(group=factor(blocksize))) +
	#  #geom_boxplot()
	#  geom_point()

	#if ( "logarithmic" == scale ) {
	#  p = p + scale_y_log10()
	#}

	#filename_eps = sprintf("%s/performance_%s_%s_%s_%s_%s_%s.eps", folder_out, app, fs, api, type, "read", scale)
	#filename_png = sprintf("%s/performance_%s_%s_%s_%s_%s_%s.png", folder_out, app, fs, api, type, "read", scale)
	#ggsave(filename_png, width = 3, height = 10)
	#ggsave(filename_eps, width = 3, height = 10)
	##system(sprintf("epstopdf %s", filename_eps))
	#system(sprintf("rm %s", filename_eps))

}}}}
}
