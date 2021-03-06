library(RMySQL)

anvnamn <- "Ditt anv�ndarnamn till SQL"
losenord <- "Ditt l�senord" #Vill man inte g�ra sitt l�senord synligt kan man skriva enligt punkt 1
databas <- "Databasnamn"
dinhost <- "Din host" #Skriv "localhost" eller "127.0.0.1" om du k�r lokalt
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
#Filen �r ungef�r 36mb 
#M�t hur l�ng tid nedan tar

system.time(testdata <- read.csv2("https://s3.amazonaws.com/geoda/data/Abandoned_Vehicles_Map.csv", 
                    header=TRUE, 
                    sep=","))

#Tar ungef�r 36 sekunder p� min dator ~ 1 sek per mb


#Extrahera information i R (ej rekommenderat f�r de som �r ovana i R - anv�nd SQL!)
vilka <- testdata[which(testdata$Vehicle.Color == "Red" & testdata$Vehicle.Make.Model == "Toyota"),]


#Skriv �ver till din SQL databas med min funktion d�r jag selektivt v�ljer ut vilka som ska ut till SQL
#Om du vill ha alla obearbetade kolumner till SQL exekvera d� utan "field.types"
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

#Anv�nd funktionen rtillsql(dataset, namn p� datasettet i SQL)
rtillsql(testdata, abbd_cars)


#St�ng av din uppkoppling mot SQL
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

#Ta hem datan fr�n SQL servern med en enkel funktion
tahemdata <- function(t,x){
  kod = paste0(x, collapse=", ") #H�r vill vi g�ra det till en enda string
  rsql = dbSendQuery(t, kod) #H�r skickar vi queryn till SQL och exekverar SQL koden
  data = fetch(rsql, n = Inf) #H�r h�mtar vi hem vald data fr�n SQL servern d�r n = Inf h�mtar hem alla rader
}

#G�r det till en data frame i R
abbd_cars <- tahemdata(mindatabas, tryout)

summary(abbd_cars)

