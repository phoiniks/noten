#!/usr/bin/Rscript

library(DBI)
library(RSQLite)
library(GetoptLong)
library(plyr)
library(epiDisplay)

args = commandArgs(trailingOnly = TRUE)

fach <- args[1]
titel <- args[2]

lz <- format(Sys.Date(), "%d. %B %Y")

qq.options("cat_prefix" = "[INFO] ", "cat_verbose" = FALSE)
f = qq(fach)
qq.options("cat_prefix" = "[INFO] ", "cat_verbose" = FALSE)
t = qq(titel)

lz <- format(Sys.Date(), "%d. %B %Y")

con = dbConnect(SQLite(), dbname = "noten.db")

dbReadTable(con, fach)

myQuery <- dbSendQuery(con, paste("SELECT schueler, zensur, punkte, zeit FROM", f))
myData <- dbFetch(myQuery, n = -1)

count(myData, 'zensur')

tab1(myData$zensur, sort.group=TRUE, cum.percent=TRUE, ylab="Häufigkeit", main=paste("Zensurenverteilung ", t, " vom ", lz))