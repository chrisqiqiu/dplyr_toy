# dplyr_toy
------------------------

-	Average number of touch points per user (User-ID column represents ID of user)
2.592412
-	Top 5 the most frequently used creative size (e.g. 300x250)
Top 5 : 300x250, 728x90, 300x50,160x600 ,300x600
-	Average time before(you mean between?) 1st and 2nd touch (ignoring same time)
8332.629 secs

-----------------------

Transform (aggregate) data into the following format:
UserID, path (could be quite long string)
where path is the string with sequence of visited sites in the form of “A > B > C”, 
where A, B and C are the site IDs touched by the user and A happened before B etc.

----------------------
Load this report using R: https://s3-ap-southeast-2.amazonaws.com/bohemia-test-tasks/CLD/ESD_Conversionreport_05182016.csv
It opens perfectly fine by Excel but it puzzled me a bit the other day. Could not open it in R as easily as other files.
Tell me what was the problem and how did you solve it

I observe the file in linux environment. I noticed there’s a weird character at the beginning of the file by using cat command to show the file. After I use “ sed '1d' ESD_Conversionreport_05182016.csv > tempFile” to remove the first line. I can open it in R. I think it is the Unicode encoding issue. It can be fixed if you use 
read.delim("./Test/unin.txt", fileEncoding="UCS-2LE") . Also , the files have different width of the rows. The real column header start at row 9. I need to remove the first few rows to properly read the file into dataframe.


