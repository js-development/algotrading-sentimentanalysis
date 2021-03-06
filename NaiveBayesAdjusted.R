source("./OurFunctions.R")
library(e1071)
library(caret)

set.seed(42)

#####READ TWEETS#####
twits_json <- "./Sources/raw.json"
twits_df_raw <- fromJSON(twits_json)

#####ADJUSTMENTS#####
twits_df_bull <- subset(twits_df_raw, tag == "Bullish")
twits_df_bear <- subset(twits_df_raw, tag == "Bearish")

sampleIds <- sort(sample(1:nrow(twits_df_bull), nrow(twits_df_bear)))

twits_df_bull <- twits_df_bull[sampleIds,]
twits_df_labeled <- rbind(twits_df_bull, twits_df_bear)
twits_df_labeled <- twits_df_labeled[sample(nrow(twits_df_labeled)), ]
twits_df_labeled$tag <- as.factor(twits_df_labeled$tag)

corpusOfTweets <- VCorpus(VectorSource(twits_df_labeled$message))

#####PREPROCESSING#####
corpusOfTweets <- stock.twits.preprocessing(corpusOfTweets, c(TRUE, TRUE, TRUE, TRUE, TRUE))

#####TERM DOCUMENT MATRIX#####
twits_tdm <- DocumentTermMatrix(corpusOfTweets)

trainTestRatio <- 0.8
trainingIds <- sort(sample(1:nrow(twits_df_labeled), nrow(twits_df_labeled)*trainTestRatio))

twits_df_train <- twits_df_labeled[trainingIds,]
twits_df_test <- twits_df_labeled[-trainingIds,]

twits_tdm_train <- twits_tdm[trainingIds,]
twits_tdm_test <- twits_tdm[-trainingIds,]

corpusOfTweets_train <- corpusOfTweets[trainingIds]
corpusOfTweets_test <- corpusOfTweets[-trainingIds]

twits_train_labels <- twits_df_labeled[trainingIds,]$tag
twits_test_labels <- twits_df_labeled[-trainingIds,]$tag

prop.table(table(twits_train_labels))
prop.table(table(twits_test_labels))

frequent_terms <- findFreqTerms(twits_tdm_train,5)

twits_tdm_freq_train <- DocumentTermMatrix(corpusOfTweets_train, control=list(dictionary = frequent_terms))
twits_tdm_freq_test <- DocumentTermMatrix(corpusOfTweets_test, control=list(dictionary = frequent_terms))

convert_counts <- function(x){
  y <- ifelse(x > 0, 1,0)
  y <- factor(y, levels=c(0,1), labels=c("Bearish", "Bullish"))
  y
}

twits_train <- apply(twits_tdm_freq_train,MARGIN = 2,convert_counts)
twits_test <- apply(twits_tdm_freq_test,MARGIN = 2,convert_counts)

twits_classifier <- naiveBayes(twits_train,twits_df_train$tag)

twits_test_pred <- predict(twits_classifier,newdata=twits_test)

table("Predictions"= twits_test_pred,  "Actual" = twits_df_test$tag )

conf.mat <- confusionMatrix(twits_test_pred, twits_df_test$tag)
conf.mat
conf.mat$byClass
conf.mat$overall
conf.mat$overall['Accuracy']