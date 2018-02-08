#install.packages('R.utils')

library(R.utils)
library(tidyverse)

#i created a folder called Test in working space just to separate the files from my other files 

# create a function to download file from a url and unzip it and read the file into memory, return it as dataframe
loadFile<- function(url) {
    
    fileName<- paste0("./Test/",gsub("https.*NetworkImpression_(.*)\\.log\\.gz",'\\1', url))
    
    download.file(url,paste0(fileName,".gz"))
    
    gunzip(paste0(fileName,".gz"))
 
    read_delim(fileName,delim="\xfe") 
}

# put all the urls in a list
list_of_files <- c("https://s3-ap-southeast-2.amazonaws.com/bohemia-test-tasks/CLD/NetworkImpression_246609_03-26-2016.log.gz",
                   "https://s3-ap-southeast-2.amazonaws.com/bohemia-test-tasks/CLD/NetworkImpression_246609_03-27-2016.log.gz",
                   "https://s3-ap-southeast-2.amazonaws.com/bohemia-test-tasks/CLD/NetworkImpression_246609_03-28-2016.log.gz")

# i use lapply here as i think it's neater than for loop
list_of_frames<- lapply(list_of_files,function(url) loadFile(url) )

# rbind all the dataframes in the list into one dataframe
df<- bind_rows(list_of_frames)
df

# observe the structure of the dataframe
str(df)

head(df,100)

df %>% summarise(distinctUserID=n_distinct(`User-ID`,na.rm=TRUE),distinctTime=n_distinct(Time),numberOfRow=n())
#984207       251781     3101915

# check if there's any na in user-id column
df %>%filter(is.na(`User-ID`) == TRUE) # return nothing

# observe the pattern of the User-ID, found there're quite a few records with only 1 character long 
df %>%group_by(nchar(`User-ID`)) %>% summarise(n())
# nchar(`User-ID`)     n()
# (int)   (int)
# 1                1  550448
# 2               28 2551467

df %>%filter(nchar(`User-ID`) == 1) %>% print(n=50)
df %>%filter( nchar(`User-ID`) == 1 ) %>% group_by(`User-ID`) %>% summarise(n()) # they are all 0
# there're quite a lot of User-id which is 0 which doesn't look right.
# so i filter it out before i calculate the Average number of touch points per user

##	Task 2 (1) Average number of touch points per user (User-ID column represents ID of user)
# get the total number of touch points and total distinct users. and then divide the total number of touch points by total distinct users
df %>%filter( nchar(`User-ID`) != 1 )%>% summarise(distinctUserID=n_distinct(`User-ID`,na.rm=TRUE),distinctTime=n_distinct(Time),numberOfRow=n())
# distinctUserID distinctTime numberOfRow
# (int)        (int)       (int)
# 1         984206       246329     2551467
2551467/984206 
# 2.592412

# or we can get the same result using mean function . I filtered the user-ID not equal to 0 out as I think it's not a valid user id
df %>%filter( nchar(`User-ID`) != 1 )%>%group_by(`User-ID`) %>%  summarise(totalNumberEachGroup=n())%>%  summarise(totalNumberEachGroup=mean(totalNumberEachGroup))

# Source: local data frame [1 x 1]
# 
# totalNumberEachGroup
# (dbl)
# 1             2.592412


##	Task 2 (2) Top 5 the most frequently used creative size (e.g. 300x250)
# group the dataframe by create size and then sort it in descending order 
df %>% group_by(`Creative-Size-ID`) %>% summarise(n=n()) %>% arrange(desc(n))

# Creative-Size-ID       n
# (chr)   (int)
# 1              0x0 1405085
# 2          300x250 1176420
# 3           728x90  263758
# 4           300x50  162879
# 5          160x600   60851
# 6          300x600   31958
# 7           320x50     711
# 8          120x600     246
# 9          970x250       7

# top 5 : 300x250, 728x90, 300x50,160x600 ,300x600

# check if the counts make sense 
df %>% summarise(distinctSiteID=n_distinct(`Site-ID`),distinctADID=n_distinct(`Ad-ID`),distinctCreativeID=n_distinct(`Creative-ID`),distinctSize=n_distinct(`Creative-Size-ID`),numberOfRow=n())

# distinctSiteID distinctADID distinctCreativeID distinctSize numberOfRow
# (int)        (int)              (int)        (int)       (int)
#  17          107                 77            9     3101915



# Task 2 (3) 	Average time before (I think you mean between?) 1st and 2nd touch (ignoring same time)

# observe the difference between 'Time' and 'Time-UTC-Sec'
df[,c('Time','Time-UTC-Sec')]

df %>%group_by(nchar(`Time-UTC-Sec`)) %>% summarise(n())

df %>% filter( `Time-UTC-Sec`  == 1458922867 ) %>% select (everything())

df %>% sample_n(100) %>% select(Time,`Time-UTC-Sec`) %>% print(n=100)

df %>%filter(nchar(`User-ID`) != 1) %>% # filter out the 0 ids which doesn't look like a real id
    group_by(`User-ID`,`Time-UTC-Sec`) %>% arrange(`User-ID`,`Time-UTC-Sec` ) %>% filter(row_number(`Time-UTC-Sec`)==1 ) %>%  # dedupe when User-ID is the same and have same touch time to ignore same touch time
    group_by(`User-ID`) %>% arrange(`Time-UTC-Sec`) %>%  filter(row_number(`Time-UTC-Sec`)<=2 ) %>% # get the first two touch time
    mutate(x=last(`Time-UTC-Sec`)-first(`Time-UTC-Sec`)) %>%  # add the calculated temp column to get the difference of first touch point and second touch point
    filter(row_number(`User-ID`) ==1 ) %>% # get one row per group for the difference we just appended as currently there're first and second touch two rows per group
    ungroup %>% summarise(AverageTimeofFirstTwoTouchPoints=mean(as.numeric(x)))  

 #8332.629 secs
# Source: local data frame [1 x 1]
# 
# AverageTimeofFirstTwoTouchPoints
# (dbl)
#                       8332.629


## Task3 advanced data transformation

# grab a random sample to observe 
df %>% sample_n(100) %>% arrange(`Time-UTC-Sec`) %>% select(Time,`Time-UTC-Sec`) %>% print(n=100)

# split the data frame based on User-ID and then sort it by time so that all the touch points of each starts from earliest to latest
# and then for each group(user-id), concatenate  all the rows in Site-ID column  of that group using " > " as delimiter
# finally output the dataframe to csv
df %>% filter(nchar(`User-ID`) != 1) %>% 
    group_by(`User-ID`) %>% arrange(`Time-UTC-Sec`)  %>% 
    summarise( path=paste0(as.character(`Site-ID`) , collapse = " > ") ) %>% select(`User-ID`,path) %>% 
    write.csv( file = "./Test/Task3.csv", row.names = FALSE)




## Task 4 

task4Frame <- read_delim("./Test/tempFile",delim="\t") 

read_delim("./Test/unin.txt",delim="\t") 

read.delim("./Test/unin.txt", fileEncoding="UCS-2LE")

read.delim("./Test/ESD_Conversionreport_05182016.csv", fileEncoding="UCS-2LE")





