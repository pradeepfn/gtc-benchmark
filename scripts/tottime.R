
print("Initializing the Rscript")
#remember initial directory
initial.dir<-getwd()
#jump to new one
print("moving in to /stats dir..")
setwd("../stats/")

tot_time = 0 
count = 0

regex<-paste('tot_*', sep="");
listfiles <- list.files(path=".",pattern=regex,full.names=TRUE);
for(filename in listfiles)
{
	data <- read.csv(file=filename ,head=FALSE,sep=":")
	temp <- data$V1[2]-data$V1[1]
	temp <- temp*1000000 + data$V2[2] - data$V2[1]
	tot_time <- tot_time + temp
	count <- count + 1
	
}

temp <- tot_time/count
print(temp)
setwd(initial.dir);

