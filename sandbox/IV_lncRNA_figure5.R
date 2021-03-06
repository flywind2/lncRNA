##making a distribution plot with transcripts and TPM
setwd("~/lncRNA")
total_exp <- read.table("total_tissue_all_TPM", header=T, stringsAsFactors=F)
refined_nolncRNA_exp <- total_exp[total_exp$id=="annotated",-1]
lncRNA_exp <- total_exp[total_exp$id=="lncRNA",-1]

#reshaping data for more easy manipulation
library(reshape2)
refined_melt <- melt(refined_nolncRNA_exp, id.vars=c("V4"))
our_lncRNA_melt <- melt(lncRNA_exp, id.vars=c("V4"))
#variance stabilizing data
library(plyr)
refined_melted_new<- ddply(refined_melt, c("V4","variable"), summarise,
                           stable=log10(value + 1))
our_lncRNA_melt_new<- ddply(our_lncRNA_melt, c("V4","variable"), summarise,
                            stable=log10(value + 1))

#Make the density plot for each
library(RColorBrewer)
library(ggplot2)
my.cols <- brewer.pal(8, "Set1")
#for just refined annotated transcripts
r <- ggplot(refined_melted_new, aes(x=stable)) + geom_density(aes(group=variable,colour=variable)) +
  xlab("log10(TPM+1)") + scale_colour_manual(values = my.cols) + xlim(-1,3)

#for our lncRNA
o <- ggplot(our_lncRNA_melt_new, aes(x=stable)) + geom_density(aes(group=variable,colour=variable)) +
  xlab("log10(TPM+1)") + scale_colour_manual(values = my.cols) + xlim(-1,3)

## Print the figures to PNG files
png(filename='Fig5A_refined.png', width=800, height=750)
print(r)
graphics.off()

png(filename='Fig5B_lncRNA.png', width=800, height=750)
print(o)
graphics.off()

#getting all the density values
refined_points<-print(r)
refined_points<-refined_points$data[[1]]
#write.table(refined_points,"refined_points.txt")

lncRNA_points<-print(o)
lncRNA_points<-lncRNA_points$data[[1]]

#make a function for calculating mode with colour as a factor
#apparently while subsetting you can not have a mix of positive anf nevatige numbers
colours <- factor(refined_points$colour)
##377EB8 #4DAF4A #984EA3 #A65628 #E41A1C #F781BF #FF7F00 ##FFFF33
#rename colour factors to tissue names
levels(colours) <- list(BrainStem="#377EB8", Cerebellum="#4DAF4A", Embryo.ICM="#984EA3", Embryo.TE="#A65628", Muscle="#E41A1C", Retina="#F781BF", Skin="#FF7F00", SpinalCord="#FFFF33")

#obtaining the TPM that has highest density for each colour (=tissue)
#getmode <- function(v) {
#  v[which.max(v$density),]
#}
#result_refined <- by(refined_points,colours, getmode, simplify=T)
#print(result_refined)

#result_lncRNA <- by(lncRNA_points,colours, getmode, simplify=T)
#print(result_lncRNA)

#Obtain interval datapoints to make P(detection) curve
#calculate areas with 0.1 TPM intervals
getAreas_please <- function(v) {for (i in 1:dim(v)[1]) {
  I<-v$x[i]-v$x[i-1]
  A<-v$density*I
}
v$area<-print(A)
}
#these are the areas for each TPM
intervals_refined <- getAreas_please(refined_points)
intervals_lncRNA <- getAreas_please(lncRNA_points)

#now attach these back to the TPM values and tissue categories
refined_area<-data.frame(cbind(refined_points$x,intervals_refined,refined_points$colour))
lncRNA_area<-data.frame(cbind(lncRNA_points$x,intervals_lncRNA,lncRNA_points$colour))
#make sure all values besides factors are numeric so we can perform calculations
refined_area[, 1] <- as.numeric(as.character( refined_area[, 1] ))
refined_area[, 2] <- as.numeric(as.character( refined_area[, 2] ))
lncRNA_area[, 1] <- as.numeric(as.character( lncRNA_area[, 1] ))
lncRNA_area[, 2] <- as.numeric(as.character( lncRNA_area[, 2] ))

#divide these intervals by AUC
#sum all the areas for each tissue, so again set colour(=tissue) as factor
colours <- factor(refined_area$V3)
#rename colour factors to tissue names
levels(colours) <- list(BrainStem="#377EB8", Cerebellum="#4DAF4A", Embryo.ICM="#984EA3", Embryo.TE="#A65628", Muscle="#E41A1C", Retina="#F781BF", Skin="#FF7F00", SpinalCord="#FFFF33")
#calculate the AUC
AUC_refined <- aggregate(intervals_refined ~ colours, refined_area, sum)
AUC_lncRNA <- aggregate(intervals_lncRNA ~ colours, lncRNA_area, sum)

#divide each interval by the respective AUC
refined <- split(refined_area, refined_area$V3)
str(refined)
# make each into a data.frame
Y <- lapply(seq_along(refined), function(x) as.data.frame(refined[[x]])) 
#Assign the dataframes in the list Y to individual objects and divide them by their
#respective AUC
library(dplyr)
#get the AUC values from above and apply manually
BS_r <- Y[[1]]
BS_r_f <- mutate(BS_r, P = intervals_refined / 0.9493)
C_r <- Y[[2]]
C_r_f <- mutate(C_r, P = intervals_refined / 0.9029)
EICM_r <- Y[[3]]
EICM_r_f <- mutate(EICM_r, P = intervals_refined / 0.8792)
ETE_r <- Y[[4]]
ETE_r_f <- mutate(ETE_r, P = intervals_refined / 0.8640)
M_r <- Y[[5]]
M_r_f <- mutate(M_r, P = intervals_refined / 0.9403)
R_r <- Y[[6]]
R_r_f <- mutate(R_r, P = intervals_refined / 0.9485)
S_r <- Y[[7]]
S_r_f <- mutate(S_r, P = intervals_refined / 0.8554)
SC_r <- Y[[8]]
SC_r_f <- mutate(SC_r, P = intervals_refined / 0.8558)
P_refined <- rbind(BS_r_f,C_r_f,EICM_r_f,ETE_r_f,M_r_f,R_r_f,S_r_f,SC_r_f)

#do for known lncRNA
lncRNA <- split(lncRNA_area, lncRNA_area$V3)
str(lncRNA)
# make each into a data.frame
X <- lapply(seq_along(lncRNA), function(x) as.data.frame(lncRNA[[x]])) 
#Assign the dataframes in the list Y to individual objects
BS_l <- X[[1]]
BS_l_f <- mutate(BS_l, P = intervals_lncRNA / 0.9459)
C_l <- X[[2]]
C_l_f <- mutate(C_l, P = intervals_lncRNA / 0.9063)
EICM_l <- X[[3]]
EICM_l_f <- mutate(EICM_l, P = intervals_lncRNA / 0.8791)
ETE_l <- X[[4]]
ETE_l_f <- mutate(ETE_l, P = intervals_lncRNA / 0.8384)
M_l <- X[[5]]
M_l_f <- mutate(M_l, P = intervals_lncRNA / 0.9433)
R_l <- X[[6]]
R_l_f <- mutate(R_l, P = intervals_lncRNA / 0.9412)
S_l <- X[[7]]
S_l_f <- mutate(S_l, P = intervals_lncRNA / 0.8587)
SC_l <- X[[8]]
SC_l_f <- mutate(SC_l, P = intervals_lncRNA / 0.8172)
P_lncRNA <- rbind(BS_l_f,C_l_f,EICM_l_f,ETE_l_f,M_l_f,R_l_f,S_l_f,SC_l_f)

#find the max P(detection) for the mode of refined genes
#and lncRNA for each tissue
getTPM <- function(v) {
  v[which.max(v$P),]
}

library(dplyr)
refined_P_max <- data.frame(do.call("rbind", by(P_refined,colours, getTPM, simplify=T)))

lncRNA_P_max <- data.frame(do.call("rbind", by(P_lncRNA,colours, getTPM, simplify=T)))

P_detect_refined_lncRNA <- cbind(refined_P_max,lncRNA_P_max)
P_detect_refined_lncRNA <- P_detect_refined_lncRNA[ ,c(1,4,5,8)]
names(P_detect_refined_lncRNA) <- c("TPM_refined_log","P_refined","TPM_lncRNA_log","P_lncRNA")

write.table(P_detect_refined_lncRNA,"P_detection_table.txt")

#plotting relationship between P(detecting genes) vs P(detecting lncRNA)
P_detections <- read.table("P_detection_table.txt", header=T, stringsAsFactors=F)
rownames(P_detections)->P_detections$Tissue
library(RColorBrewer)
library(ggplot2)
png(filename='Fig5C.png', width=800, height=750)
my.cols <- brewer.pal(8, "Set1")
d <- ggplot(P_detections) +
  geom_point(aes(x=P_refined,y=P_lncRNA,colour=Tissue),size=3) + 
  scale_colour_manual(values = my.cols) + 
  xlab("P(detecting mode expression of PCG)") +
  ylab("log10(P(detecting mode expression of lncRNA))") +
  scale_y_log10(breaks = c(0.01,0.02,0.03,0.04,0.05,0.06,0.1,0.2,0.3,0.4,0.5,0.6))
print(d)
graphics.off()
