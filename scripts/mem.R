mean_rd_time<-function(filelist)
{
	mrgddata <- do.call(rbind, lapply(filelist, read.csv));
	read_byte_time<-(sum(mrgddata$micro_sec)/sum(mrgddata$bytes));
	val <- c(read_byte_time*2^20*10,mean(mrgddata$micro_sec),mrgddata$bytes[1]/2^20);
}

rd_time<-function(filelist)
{
	mrgddata<-do.call(rbind, lapply(filelist, read.csv));
	val <- c(mean(mrgddata$micro_sec),mrgddata$bytes[1]/2^20);
}

print("Initializing the Rscript")
#remember initial directory
initial.dir<-getwd()
#jump to new one
print("moving in to /stats dir..")
setwd("../stats/")

orig_time_vec<-numeric();
bytes_vec<-numeric();
num_vec<-numeric();
for(i in seq(50,401,by=50))
{
	regex<-paste('nvram_n8_p._mpsi',i,'\\.log$', sep="");
	listfiles <- list.files(path="./",pattern=regex,full.names=TRUE);
	ans<-rd_time(listfiles);
	orig_time_vec<-c(orig_time_vec,ans[1]);
	bytes_vec<-c(bytes_vec,ans[2]);
	num_vec<-c(num_vec,i);
}
orig_time_vec
bytes_vec

setwd(initial.dir);

pdf("var_mem.pdf");
par(mfrow=c(1,2))
barplot(num_vec,bytes_vec,main="bytes read",xlab="mpsi values")
plot(num_vec,orig_time_vec,type="l",col="red");
dev.off();

