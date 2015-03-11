
print("Initializing the Rscript")
#remember initial directory
initial.dir<-getwd()
#jump to new one
print("moving in to /stats dir..")
setwd("../stats/")

tot_time = 0 
count = 0

init_time <- numeric()
populate_status <- numeric()
compute <- numeric()

regex<-paste('time_*', sep="");
listfiles <- list.files(path=".",pattern=regex,full.names=TRUE);
for(filename in listfiles)
{
	data <- read.csv(file=filename ,head=FALSE,sep=":")
	
	temp <- data$V1[2]-data$V1[1]
	temp <- temp*1000000 + data$V2[2] - data$V2[1]
	init_time <- c(init_time,temp)

	temp <- data$V1[3]-data$V1[2]
	temp <- temp*1000000 + data$V2[3] - data$V2[2]
	populate_status <- c(populate_status,temp)

	if(!is.na(data$V1[4])){
		temp <- data$V1[4]-data$V1[3]
		temp <- temp*1000000 + data$V2[4] - data$V2[3]
		compute <- c(compute,temp)
	}
}

print(mean(init_time))
print(mean(populate_status))
print(mean(compute))
setwd(initial.dir);

