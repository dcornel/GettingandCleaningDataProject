library(plyr)
library(reshape2)
run_analysis <- function()
{
        fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"        
        
        temp <-tempfile()
        tempd <- tempdir()
        download.file(fileURL,temp)
        
        unzip(temp, exdir = tempd)
        
        features <- read.table( paste(tempd,"\\UCI HAR Dataset\\features.txt", sep=""), encoding ="UTF-8", sep = "")
        activity_labels <- read.table(paste(tempd,"\\UCI HAR Dataset\\activity_labels.txt",sep=""), encoding ="UTF-8", sep = "")                
        
        test_merged <- getdatasets(tempd, "test", features, activity_labels)
        train_merged <- getdatasets(tempd, "train", features, activity_labels)
        
        unlink(temp)
        unlink(tempd)
        
        final_merged <- rbind(train_merged, test_merged)
        
        final_merged <- cbind(id=1:nrow(final_merged), final_merged)   # raw data

        labels <- getMeanStdLables(features[,2])

        meanstdtable <- cbind(final_merged[,c("subject","activityname")],final_merged[, c(labels)])
        
        transformedlabels <- transform_actions_name(labels)

        colnames(meanstdtable) <- append(c("subject", "activityname"),transformedlabels)
        meltmeans<- get_means(meanstdtable)
        
        meltmeans <- cbind(id=1:nrow(meltmeans), meltmeans)
        write.table(meltmeans, file = "tidydataset.txt", col.names=T,sep="\t", quote = FALSE,row.names=FALSE )
        
        produce_codebook(meltmeans)
        
        return(meltmeans)
}


getMeanStdLables <- function(labelsvector)
{               
        
        labels <- labelsvector[1]
        for (i in 2:length(labelsvector))
        {
                if (grepl("-mean\\(\\)", labelsvector[i]) | grepl("-std\\(\\)", labelsvector[i]))
                {
                       labels<-paste(labels, labelsvector[i])
                }
                          
        }
        labels <- as.character(labels)
        labels <- unlist(strsplit(labels, " "))
        
        return(labels)
}



transform_actions_name <- function(labels)
{
        for(i in 1 : length(labels))
        {
                temp<-labels[i]
                temp<- paste("Calculated",temp,sep="", collapse = NULL)
                temp <- gsub("\\(","", temp)
                temp <- gsub("\\)","", temp)
                if (grepl("Calculatedt", temp) & grepl("-mean", temp)) #average time
                { 
                        temp <- gsub("Calculatedt","Calculatedaveragetime", temp)
                }
                
                if (grepl("Calculatedt", temp) & grepl("-std", temp)) #average time
                { 
                        temp <- gsub("Calculatedt","Calculatedstandardtimedeviation", temp)
                }
                
                if (grepl("Calculatedf", temp) & grepl("-mean", temp)) #average time
                { 
                        temp <- gsub("Calculatedf","Calculatedaveragefrequency", temp)
                }
                
                if (grepl("Calculatedf", temp) & grepl("-std", temp)) #average time
                { 
                        temp <- gsub("Calculatedf","Calculatedstandardfrequencydeviation", temp)
                }
                
                 
                temp <- gsub("-X","forx", temp)
                temp <- gsub("-Y","fory", temp)
                temp <- gsub("-Z","forz", temp)
                
                temp <- gsub("BodyBody","body", temp)
                
                        
                temp <- gsub("-mean","", temp)
                temp <- gsub("-std","", temp)
                
                
                
                labels[i]<-tolower(temp)
        }
        
        return(labels)
}

getdatasets <- function (tempd, folder, features, activity_labels)
{
        subject_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\subject_",folder,".txt", sep=""), encoding ="UTF-8")
        y_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\y_",folder,".txt", sep=""), encoding ="UTF-8")
        X_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\X_",folder,".txt", sep=""), encoding ="UTF-8", sep = "")                
        colnames(X_folder) <- as.vector(features[,2]) #add the corresponding column names to X_train from features
        
        subject_folder <- cbind(id=1:nrow(subject_folder), subject_folder) #add ID column to subject test
        colnames(subject_folder) <- c("id", "subject") # add names to the column for subject test data.frame
        
        X_folder <- cbind (id=1:nrow(X_folder), X_folder) #add ID column to X_test        
        
        subject_folder[, "activityname"] <-  sapply(y_folder, function(x) activity_labels[x, 2])
        
        folder_merged <- merge(subject_folder, X_folder, by.x = "id", by.y = "id")  
        folder_merged$id <- NULL
        
        return(folder_merged) 
}

get_means <- function(frame)
{
        # 1 WALKING 2 WALKING_UPSTAIRS 3 WALKING_DOWNSTAIRS 4 SITTING 5 STANDING 6 LAYING
        mymelt <- melt(frame,c("subject","activityname"))
        mycast<-dcast(mymelt,subject + activityname ~ variable,mean)
        return(mycast)
}

produce_codebook<- function(datatable)
{
        #code<- "<html><body><table border=\"\"><tr><th width =\"100%\" >Codebook for Human Activity Recognition Using Smartphones Dataset </th></tr>
        #        <tr><th>(subset of variables relating to mean and standard deviation) </th></tr>"
        
        code<- "<html><body><p><b>Codebook for Human Activity Recognition Using Smartphones Dataset</b></p>
                <p><b>(subset of variables relating to mean and standard deviation)</b></p><br/><table>"
        
        code <- paste(code, "<tr><td>Variable Name</td> <td>Variable position</td><td>Variable Explaination</td><td>Data Type</td><td>Values</td>  </tr>", sep="\n")
        
        columns <- colnames(datatable)
        for(i in 1:length(columns))
        {
                expl <- generate_explaination(columns[i])
                code <- paste(code, "<tr><td>",columns[i],"</td> <td>",i,"</td><td>",expl,"</td><td>Numeric</td><td>Normalized numeric values - bounded within [-1,1]</td></tr>", sep="\n")              
        
        }
        
        code <- paste(code, "</table></body></html>", sep="\n")
        write.table(code, file = "CodeBook.md", col.names=T,sep="\t", quote = FALSE,row.names=FALSE )

}

generate_explaination <- function(name)
{
        temp <- name
        
        temp <- gsub("calculatedaveragetime","Calculated average time domain ", temp)      
        temp <- gsub("calculatedstandardtimedeviation","Calculated standard time domain deviation ", temp)
        temp <- gsub("calculatedaveragefrequency","Calculated average frequency domain ", temp)
        temp <- gsub("calculatedstandardfrequencydeviation","Calculated standard frequency domain deviation ", temp)
        temp <- gsub("bodyacc","for body acceleration signals from the accelerometer ", temp)
        temp <- gsub("gravityacc","for gravitational acceleration signals from the accelerometer ", temp)
        temp <- gsub("bodygyro","for body acceleration signals from the gyroscope  ", temp)       
        temp <- gsub("forx","for axe X ", temp)
        temp <- gsub("fory","for axe Y ", temp)
        temp <- gsub("forz","for axe Z  ", temp)
        temp <- gsub("mag","by magnitude ", temp)
        temp <- gsub("jerk","(time to obtain Jerk signals)  ", temp)
        
        
        return(temp)
        
}
 