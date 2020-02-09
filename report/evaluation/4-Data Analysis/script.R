  data <- read.csv("C:/Users/dodos/Desktop/R-analysis/data.csv", row.names=1, sep=";")
  
  
  basefolder <- "C:/Users/dodos/Desktop/R-analysis/"
  
  is_musician <- data$X1 == 'Y'
  
  
  
  mus_count <-  sum(is_musician, na.rm = TRUE)
  tot <-  nrow(data)
  
  musicians_percentage <-  mus_count/tot
  print(paste("Musicians are: ", musicians_percentage*100, "% of the total number of participants"))
  
  
  print(
    paste("Musicians report an average ",
          mean(data[is_musician,'X2']), 
          "on a 1-5 scale describing how much music is part of their average day (SD: ", 
          sd(data[is_musician,'X2']) ,
          ")"
    )
  )
  
  print(
    paste("NON-Musicians report an average ",
          mean(data[!is_musician,'X2']), 
          "on a 1-5 scale describing how much music is part of their average day (SD: ", 
          sd(data[!is_musician,'X2']) ,
          ")"
    )
  )
  
  
  
  
  
  
  
  
  
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","GameImprovement.pdf"))
  title <- "Improvement due to using other interface"
  boxplot(data[!is_musician,'X12'],data[is_musician,'X12'], names=c("Non-musicians","Musicians"), main=title)
  dev.off()
  
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","TimeImprovement.pdf"))
  title <- "Improvement due to gaining experience with time"
  boxplot(data[!is_musician,'X13'],data[is_musician,'X13'], names=c("Non-musicians","Musicians"), main=title)
  dev.off()
  
  
  
  is_audio <- data$X3 == 'A'
  
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","OnlyAudio-TimevsGame.pdf"))
  title <- "Improvement due to game vs due to time experience (Audio players)"
  boxplot(data[is_audio,'X12'],data[is_audio,'X13'], names=c("Game Improvement","Time Improvement"), main=title)
  dev.off()
  
  dmean_gameimprovement = mean(data[is_audio,'X12'])
  dmean_timeimprovement = mean(data[is_audio,'X13'])
  
  print(paste("Game improvement mean: ", dmean_gameimprovement))
  print(paste("Time improvement mean: ", dmean_timeimprovement))
  
  
  
  
  
  
  
  
  # 
  # a4 <- mean(data$X4)
  # a5 <- mean(data$X5)
  # a6 <- mean(data$X6)
  # barplot(c(a4,a5,a6), main="Mannequin first interaction",
  #         names=c("Valence","Arousal","Control"),ylim=c(0,5))
  # 
  # a8 <- mean(data$X8)
  # a9 <- mean(data$X9)
  # a10 <- mean(data$X10)
  # barplot(c(a8,a9,a10), main="Mannequin third interaction",
  #         names=c("Valence","Arousal","Control"),ylim=c(0,5))
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","Valence.pdf"))
  # Emotional VALENCE between first and third interaction
  valence1 <- mean(data$X4)
  valence2 <- mean(data$X8)
  barplot(c(valence1,valence2), main="Emotional Valence",
          names=c("First interaction","Third interaction"),
          ylim=c(0,5),
          width=c(0.2,0.2))
  dev.off();
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","Arousal.pdf"))
  # Emotional AROUSAL between first and third interaction
  arousal1 <- mean(data$X5)
  arousal2 <- mean(data$X9)
  barplot(c(arousal1,arousal2), main="Emotional Arousal",
          names=c("First interaction","Third interaction"),
          ylim=c(0,5),
          width=c(0.2,0.2))
  dev.off();
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","Control.pdf"))
  # Emotional CONTROL between first and third interaction
  control1 <- mean(data$X6)
  control2 <- mean(data$X10)
  barplot(c(control1,control2), main="Emotional Control",
          names=c("First interaction","Third interaction"),
          ylim=c(0,5),
          width=c(0.2,0.2))
  dev.off();
  
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","General.pdf"))
  intuitive <- mean(data$X11.1)*100
  interest <- mean(data$X11.2)*100
  pleasure <- mean(data$X11.3)*100
  
  all <-  c(intuitive, 100-intuitive,interest, 100-interest,pleasure, 100-pleasure)
  percentages <- matrix(all,nrow = 2)
  colnames(percentages) <- c("Intuitive (dark) vs\nIncomprehensible",
                             "Interesting (dark) vs\nBoring",
                             "Pleasant (dark) vs\nUnpleasant")
  
  
  barplot(percentages, main="General appreciation metrics (bipolar attributes)",
          ylim=c(0,100))
  dev.off();
  
  
  pdf(paste("C:/Users/dodos/Desktop/R-analysis/","Text.pdf"))
  plot.new()
  tx <- paste("Musicians are: ", musicians_percentage*100, "% of the total number of participants")
  text(x = 0.5,y=1,labels = c(tx),cex = 0.8)
  tx <- paste("Musicians report an average ",
              round(mean(data[is_musician,'X2']),2), 
              "on a 1-5 scale describing how\n much music is part of their average day (SD: ", 
              sd(data[is_musician,'X2']) ,
              ")"
  )
  text(x = 0.5,y=0.9,labels = c(tx),cex = 0.8)
  
  tx <- paste("NON-Musicians report an average ",
          mean(data[!is_musician,'X2']), 
          "on a 1-5 scale describing how\n much music is part of their average day (SD: ", 
          sd(data[!is_musician,'X2']) ,
          ")"
    )
  text(x = 0.5,y=0.72,labels = c(tx),cex = 0.8)

  
  tx <- paste("Game improvement mean for audio users (non musicians): ", dmean_gameimprovement)
  text(x = 0.5,y=0.60,labels = c(tx),cex = 0.8)
  
  tx <- paste("Time improvement mean for audio users (non musicians): ", dmean_timeimprovement)
  text(x = 0.5,y=0.45,labels = c(tx),cex = 0.8)
  
  dev.off();
  
  
