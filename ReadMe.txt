====================================================================================
Getting and Cleaning Data
Course Project
25/05/2014
ReadMe.txt V0.1
====================================================================================
Student: Corneliu Dicusar
====================================================================================
The requirement for this project were the following:

Here are the data for the project:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

 You should create one R script called run_analysis.R that does the following. 

    1)	Merges the training and the test sets to create one data set.
    2)	Extracts only the measurements on the mean and standard deviation for each measurement. 
    3)	Uses descriptive activity names to name the activities in the data set
    4)	Appropriately labels the data set with descriptive activity names. 
    5)	Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
====================================================================================
Getting Data: 
The archive in scope is downloaded from the provided URL into a temporary file. Afterwards it is unzipped into a temporary directory.
The following data.tables are loaded from the files in the archive:
	- features - data.table containing the features from the file features.txt
	- activity_labels - data.table containing the activity labels from the file activity_labels.txt
	- subject_folder - data.table containing the list of subjects (called twice in the function: getdatasets, once for the train folder and one for the test folder)
	- y_folder - data.table containing the list of activity ids(numeric) (called twice in the function: getdatasets, once for the train folder and one for the test folder)
	- X_folder - data.table containing the all the recorded indicators (called twice in the function: getdatasets, once for the train folder and one for the test folder)
After all the data.table have been loaded, the temporary file and the temporary folder are deleted using the unlist() function
====================================================================================
Function getdatasets(tempd, folder, features, activity_labels):
arguements: 
	- tempd - temporary directory where the downoalded archive with the files is stored
	- folder - one of the two optinons: "test", "train", used to dynamically build the URLs
	- features - the list of features 
	- activity_labels - the list of activity labels: WALKING WALKING_UPSTAIRS WALKING_DOWNSTAIRS SITTING STANDING LAYING

Purpose: produce the combined data.table of the records in the test and train directories.
The paths to the right directories are built dynamically and are depenent on the value of the folder parameter:
		subject_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\subject_",folder,".txt", sep=""), encoding ="UTF-8")
        y_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\y_",folder,".txt", sep=""), encoding ="UTF-8")
        X_folder <- read.table(paste(tempd,"\\UCI HAR Dataset\\",folder,"\\X_",folder,".txt", sep=""), encoding ="UTF-8", sep = "")                

If folder = test the above three lines will read subject_folder, y_folder and  X_folder data.tables in the test directory.
Similarlly if folder = train the above three lines will read subject_folder, y_folder and  X_folder data.tables in the train directory.

X_folder contains all the records in the X_test or X_train files. Since the names of the columns are both the same and stored in the features.txt, 
the header values for X_folders are added by: colnames(X_folder) <- as.vector(features[,2])

subject_folder and X_folder data.tables are given an id column on which they will be merged later:
subject_folder <- cbind(id=1:nrow(subject_folder), subject_folder) #add ID column to subject test        
	X_folder <- cbind (id=1:nrow(X_folder), X_folder) #add ID column to X_test

additionally the subject_folder data.tables is getting a new column containing the English translation of the activies the subjects have been performing:
	subject_folder[, "activityname"] <-  sapply(y_folder, function(x) activity_labels[x, 2])

The subject_folder(not containig the activity labels as well) is merged with X_folder data.table to form the folder_merged by the id column
 which is a data.table containing the information from all 3 files in one folder (subject_test or subject_train, X_test or X_train, y_test or y_train)
	folder_merged <- merge(subject_folder, X_folder, by.x = "id", by.y = "id")  
the function getdatasests returns folder_merged
====================================================================================
Combining training data and test data:

In the main run_analysis function getdatasests function is called twice, once with the folder = train to obtain: train_merged and once with folder = test and get
 train_merged 
	test_merged <- getdatasets(tempd, "test", features, activity_labels)
	train_merged <- getdatasets(tempd, "train", features, activity_labels
	
Train_merged is appended with test_merged to obtain the complete set of records (we know that the original dataset has been split into 2: for testing and trainign purposes)
	final_merged <- rbind(train_merged, test_merged). 
This is the data.set neede in the first requirement.
====================================================================================
Selecting the columns with means and standard deviation:
	
The labels for the 561 recorded indicators are stored in features[,2]. Only a subset of the label names are selected, determined by calling the function: getMeanStdLables.
This looks for all labels that have -mean() and -std() in the name, because from the documentation for the provided data set results that the values that hold the mean 
and std have mean() std() in their name. Note: tBodyAccJerkMean, tBodyGyroMean, tBodyGyroJerkMean are not in scope because these are related to the angle() operation,
and not mean() or std().

Selecting the appropriate column header is done through:
	if (grepl("-mean\\(\\)", labelsvector[i]) | grepl("-std\\(\\)", labelsvector[i]))  { labels<-paste(labels, labelsvector[i])}

The function getMeanStdLables returns a list of header names that relate only to the mean and standard deviation. The list is used to subset the final_merged
data.table on the columns with the headers in the list. The resulted meanstdtable contains the columns: "subject" (the subject number 1..30), "activityname" (the name of the activity)
and all the columsn in the list.

In total 66 columns have been found to contain either mean() or std()
====================================================================================
Transforming labels:

once meanstable has been obtained in order to add headers to the columns, the column names will go through a cleansing activity to bring them in line
with the R varibale and fucntion naming standards and make them more readable. The function transform_actions_name is passed the list of header names of columns relating to header and std. 
The following transformations are applied to all headers:
	1) All headers will start with "calculated"
	2) both "(" and ")" are eliminated
	3) if a header start with t and is ending in -mean(), it will be changed to start with Calculatedaveragetime
	4) if a header start with t and is ending in -std(), it will be changed to start with Calculatedstandardtimedeviation
	5) if a header start with f and is ending in -mean(), it will be changed to start with Calculatedaveragefrequency
	6) if a header start with f and is ending in -std(), it will be changed to start with Calculatedstandardfrequencydeviation
	7) if a header ends in -X it will be changed to end in forx
	8) if a header ends in -Y it will be changed to end in fory
	9) if a header ends in -Z it will be changed to end in forz
	10) -mean and -std at the end of the header are going to be removed
	11) some headers have been found to contain BodyBody this has been changed to "body"
	12) all letters have been changed to lowercase
Examples of the resulting fields: calculatedaveragetimebodyaccforx,	calculatedaveragetimebodyaccforz, calculatedstandardtimedeviationbodyaccforx, calculatedstandardfrequencydeviationbodyaccforz

Further expanding the header name was considered uncessary, it would make the headers impossible to read otherwise and defeat the purpose of bringing more clarity in the labels.

====================================================================================
Final data.table with means columns:

After the headers have been transformed into version that give more information, they have been applied to the meanstdtable data.table. 

An id column was added as well in icremental values from 1 to lenght(meanstdtable), because having a id column is a good practice.

In total the meanstable has 69 columns:
	- id
	- subject - the number of the subject on which the experient was conducted
	- activityname - the name in natural language of the activity performed:WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING LAYING. It has been
	considered that these values do not require cleansing, as they are part of observations and not the headers, hence no transformation should be applied.
	- 66 columns with transformed headers for measurments relating to means and standard deviation.
	
The table meanstdtable is the data.table needed for second, third and forth requirement.

====================================================================================
tidy data with with averages by subject and activity:

The final requirement asks to create a tidy data.table that would show only the averages for each sensor groupped by subject and activity.
As an input the previously created meanstdtable data.table was taken.

The function get_means that gets as input the meanstdtable produces the required data.table.  this is achieved by sequentially applying the melt and dcast function7
from the library  reshape2. Melting is done by c("subject", "activityname") and dcast is done by the same variables.

        mymelt <- melt(frame,c("subject","activityname"))
        mycast<-dcast(mymelt,subject + activityname ~ variable,mean)
		return(mycast)
		
Once the function get_means is called in the run_analysis, an id column is added to the resulting tidy data.table, and it is exported into a file called:  tidydataset.txt
which is "\t" delimited, and has all the cleaned headers. This can be easily loaded into any software taht works with tab delimited files (like MS Excel) and can be seen
as a tidy table.

This tidy data is the requirement number 5.