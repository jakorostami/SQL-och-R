library(RMySQL)

anvnamn <- "Ditt användarnamn till SQL"
losenord <- "Ditt lösenord" #Vill man inte göra sitt lösenord synligt kan man skriva enligt punkt 1
databas <- "Databasnamn"
dinhost <- "Din host" #Skriv "localhost" eller "127.0.0.1" om du kör lokalt
dinport <- 3306

#Punkt 1
rstudioapi::askForPassword("Database password") #Detta fylls i nedan connection

mindatabas <- dbConnect(MySQL(),
                  user = anvnamn,
                  password = losenord, #Alternativt rstudioapi::askForPassword("Database password") ,
                  dbname = databas,
                  host = dinhost,
                  port = dinport)

#Exempel stort dataset "https://s3.amazonaws.com/geoda/data/Abandoned_Vehicles_Map.csv"
#Filen är ungefär 36mb 
#Mät hur lång tid nedan tar

system.time(testdata <- read.csv2("https://s3.amazonaws.com/geoda/data/Abandoned_Vehicles_Map.csv", 
                    header=TRUE, 
                    sep=","))

#Tar ungefär 36 sekunder på min dator ~ 1 sek per mb


#Extrahera information i R (ej rekommenderat för de som är ovana i R - använd SQL!)
vilka <- testdata[which(testdata$Vehicle.Color == "Red" & testdata$Vehicle.Make.Model == "Toyota"),]


#Skriv över till din SQL databas med min funktion där jag selektivt väljer ut vilka som ska ut till SQL
#Om du vill ha alla obearbetade kolumner till SQL exekvera då utan "field.types"
rtillsql <- function(t,x){
  namnet <- deparse(substitute(x))
  dbWriteTable(conn=mindatabas, name = namnet, value = as.data.frame(t), overwrite = TRUE, row.names=FALSE,
               field.types=c(Creation.Date="date", Completion.Date="date",
                             Vehicle.Make.Model="varchar(20)",
                             Vehicle.Color="varchar(20)", 
                             Status ="varchar(40)", 
                             Service.Request.Number = "varchar(40)",
                             Type.Of.Service.Request = "varchar(40)",
                             License.Plate = "varchar(50)",
                             ))
  
}

#Använd funktionen rtillsql(dataset, namn på datasettet i SQL)
rtillsql(testdata, abbd_cars)


#Stäng av din uppkoppling mot SQL
on.exit(dbDisconnect(mindatabas))




##Koppla upp dig mot SQL servern
mindatabas <- dbConnect(MySQL(),
                        user = anvnamn,
                        password = losenord, #Alternativt rstudioapi::askForPassword("Database password") ,
                        dbname = databas,
                        host = dinhost,
                        port = dinport)

#Kolla vilken data som finns i SQL servern
dbListTables(mindatabas)

#Kolla vilka kolumner som finns i valt dataset
dbListFields(mindatabas, "abbd_cars")

#Definiera SQL koden
tryout <- "select * from abbd_cars"

#Ta hem datan från SQL servern med en enkel funktion
tahemdata <- function(t,x){
  kod = paste0(x, collapse=", ") #Här vill vi göra det till en enda string
  rsql = dbSendQuery(t, kod) #Här skickar vi queryn till SQL och exekverar SQL koden
  data = fetch(rsql, n = Inf) #Här hämtar vi hem vald data från SQL servern där n = Inf hämtar hem alla rader
}

#Gör det till en data frame i R
abbd_cars <- tahemdata(mindatabas, tryout)

summary(abbd_cars)

