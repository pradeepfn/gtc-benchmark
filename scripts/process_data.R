mean_rd_time<-function(filelist)
{
	mrgddata <- do.call(rbind, lapply(filelist, read.csv));
	read_byte_time<-(sum(mrgddata$micro_sec)/sum(mrgddata$bytes));
	val <- c(read_byte_time*2^20*10,mean(mrgddata$micro_sec),mrgddata$bytes[1]/2^20);
}



print("Initializing the Rscript")
#remember initial directory
initial.dir<-getwd()
#jump to new one
print("moving in to /stats dir..")
setwd("../stats/")
process_vec<-numeric();
norm_time_vec<-numeric();
orig_time_vec<-numeric();
bytes_vec<-numeric();
for(i in seq(2,11,by=2))
{
	regex<-paste('nvram_n',i,'.*\\.log$', sep="");
	listfiles <- list.files(path="./",pattern=regex,full.names=TRUE);
	ans<-mean_rd_time(listfiles);
	process_vec<-c(process_vec,length(listfiles));
	norm_time_vec<-c(norm_time_vec,ans[1]);	
	orig_time_vec<-c(orig_time_vec,ans[2]);
	bytes_vec<-c(bytes_vec,ans[3]);
	cat("time to read 10MB of data for ",length(listfiles),"processes : ",ans,"\n");
}
process_vec
norm_time_vec
orig_time_vec
bytes_vec
df<-data.frame(process_vec,norm_time_vec,orig_time_vec);
max_y<-max(df);
cat("Done processing files...\n");

setwd(initial.dir);

pdf("byte_read.pdf");
par(mfrow=c(1,2))
barplot(bytes_vec,main="Number of bytes read in each node",xlab="MPI processes(N)")
plot(process_vec,norm_time_vec,type="l",col="red",ylim=c(4000,max_y));
lines(process_vec,orig_time_vec,type="l",col="red");
dev.off();

