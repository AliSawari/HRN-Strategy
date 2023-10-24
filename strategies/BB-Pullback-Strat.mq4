#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description "BollingerBands Pullback in RANGE Indicator"

#include <stdlib.mqh>
#include <stderror.mqh>

// indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "BB-R Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "BB-R Sell"

// Indicator CONST values based on Strategy
const string ALERT_MSG_BUY = "Buy BB-";
const string ALERT_MSG_SELL = "Sell BB-";
const int BB_SHORT = 8;
const int BB_LONG1 = 100;
const int BB_LONG2 = 200;
const int BB_LONG3 = 400;
const int BB_OFFSET = 2;
const int BB_DEV = 2;
const int RSI_LEN = 14;
const int RSI_UPPER = 69;
const int RSI_LOWER = 31;
const string SYMBOL = Symbol();
extern const float SL_To_Body_Ratio = 0.25;

// indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
double myPoint; //initialized in OnInit

// custom made alert function for better messages
void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = "BB-Pullback";
  if(type == "print") Print(message);
  else if(type == "error") Print(type + MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | "+message);
  else if(type == "indicator") {
    Print(MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message );
    Alert(MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message);
    SendNotification(MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message);
  }
}

// used to correctly compare doubles in MQ4
bool isDoublesEqual(double number1, double number2) { 
   if(NormalizeDouble(number1-number2,8)==0) return true;
   else return false;
}


// calculates the OHLC values for every given candlestick
void getOHLC(int candleIndex, double& results[]){
  double O = iOpen(SYMBOL, PERIOD_CURRENT, candleIndex);
  double H = iHigh(SYMBOL, PERIOD_CURRENT, candleIndex);
  double L = iLow(SYMBOL, PERIOD_CURRENT, candleIndex);
  double C = iClose(SYMBOL, PERIOD_CURRENT, candleIndex);
  ArrayFill(results, 0, 1, O);
  ArrayFill(results, 1, 1, H);
  ArrayFill(results, 2, 1, L);
  ArrayFill(results, 3, 1, C);
}

// calculates the BollingerBand values for every given candlestick
void getBands(int candleIndex, int BB_LEN, double& results[]){
  double UpperBB = iBands(SYMBOL, PERIOD_CURRENT, BB_LEN, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, candleIndex);
  double LowerBB = iBands(SYMBOL, PERIOD_CURRENT, BB_LEN, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, candleIndex);
  ArrayFill(results, 0, 1, UpperBB);
  ArrayFill(results, 1, 1, LowerBB);
}

// checks whether or not a given candle is hitting any given BollingerBand
bool isHittingBB(int candleIndex, int BB_LEN, bool hitUp){
  double originalBands[2];
  double offsetBands[2];
  getBands(candleIndex, BB_LEN, originalBands);
  getBands(candleIndex, (BB_LEN - BB_OFFSET), offsetBands);
  double OHLC[4];
  getOHLC(candleIndex, OHLC);
  bool isHit;
  if(hitUp) isHit = (OHLC[1] >= originalBands[0] && OHLC[2] <= originalBands[0]) || (OHLC[1] >= offsetBands[0] && OHLC[2] <= offsetBands[0]);
  else isHit = (OHLC[1] >= originalBands[1] && OHLC[2] <= originalBands[1]) || (OHLC[1] >= offsetBands[1] && OHLC[2] <= offsetBands[1]);
  return isHit;
}

// checks whether or not the RSI values for a given candlestick are suitable for entering a position
bool isRSIValid(int candleIndex, bool hitUp){
  double RSI = iRSI(SYMBOL, PERIOD_CURRENT, RSI_LEN, PRICE_CLOSE, candleIndex);
  bool isValid;
  if(hitUp) isValid = MathCeil(RSI) >= RSI_UPPER;
  else isValid = MathFloor(RSI) <= RSI_LOWER;
  return isValid;
}

void getBodyAndShadows(int candleIndex, double &results[]){
  double OHLC[4];
  getOHLC(candleIndex, OHLC);
  double Open = OHLC[0];
  double High = OHLC[1];
  double Low = OHLC[2];
  double Close = OHLC[3];
  const double body_len =  MathAbs(Open - Close);
  const double upperShadow =  MathAbs(High - MathMax(Open, Close));
  const double lowerShadow =  MathAbs(MathMin(Open, Close) - Low);
  ArrayFill(results, 0, 1, body_len);
  ArrayFill(results, 1, 1, upperShadow);
  ArrayFill(results, 2, 1, lowerShadow);
}

void calcTPandSL(bool hitUp, double& results[]){
  double TP;
  double SL;
  double OHLC[4];
  double BodyAndShadows[3];
  getOHLC(1, OHLC);
  getBodyAndShadows(1, BodyAndShadows);
  const double High = OHLC[1];
  const double Low = OHLC[2];
  const double Close = OHLC[3];
  const double BodyLen = BodyAndShadows[0]; 
  double ratio = (SL_To_Body_Ratio * BodyLen);

  if(hitUp){
    SL = High + ratio;
    double d1 = SL - Close;
    TP = Close - d1;
  } else {
    SL = Low - ratio;
    double d2 = Close - SL;
    TP = Close + d2;
  }
  ArrayFill(results, 0, 1, TP);
  ArrayFill(results, 1, 1, SL);
}



int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]){
    
    return(rates_total);
}

datetime NewCandleTime = TimeCurrent();

bool IsNewCandle(){
   // If the time of the candle when the function ran last
   // is the same as the time this candle started,
   // return false, because it is not a new candle.
   if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
   // Otherwise, it is a new candle and we need to return true.
   else {
    // If it is a new candle, then we store the new value.
      NewCandleTime = iTime(Symbol(), 0, 0);
      return true;
   }
}


void openOrder(bool hitUp, double TP, double SL){
  int rand = MathRand();
  string msg = hitUp ? " Sell Order " : " Buy order " ;
  PrintFormat("About to %s with TP: %e and SL: %e", msg, TP, SL);
  if(hitUp) OrderSend(Symbol(), OP_SELL, 0.01, Bid, 1, SL, TP, msg, rand, 0, clrRed);
  else OrderSend(Symbol(), OP_BUY, 0.01, Ask, 1, SL, TP, msg, rand, 0, clrGreen);
  OrderPrint();
}




void OnTick() {
  if(IsNewCandle()){
    //--- counting from 0 to rates_total
    ArraySetAsSeries(Buffer1, true);
    ArraySetAsSeries(Buffer2, true);
  //--- initial zero

    int i = 0;
    double BB_small_1_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_small_1_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);
    double BB_small_2_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+2);
    double BB_small_2_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+2);

    double BB_Long1_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG1, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long1_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG1, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);

    double BB_Long2_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG2, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long2_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG2, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);

    double BB_Long3_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG3, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long3_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG3, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);


    // Candle Values
    double body1 = MathAbs(Close[i+1] - Open[i+1]);
    double body2 = MathAbs(Close[i+2] - Open[i+2]);
    double body1Top = MathMax(Open[i+1], Close[i+1]);
    double body2Top = MathMax(Open[i+2], Close[i+2]);
    double body1Bottom = MathMin(Open[i+1], Close[i+1]);
    double body2Bottom = MathMin(Open[i+2], Close[i+2]);
    double upperShadow1 = High[i+1] - body1Top;
    double upperShadow2 = High[i+2] - body2Top;
    double lowerShadow1 = body1Bottom - Low[i+1];
    double lowerShadow2 = body2Bottom - Low[i+2];

    // is 2CBB pattern Buy 
    bool isCurrentBullish = Close[i+1] > Open[i+1];
    bool isHigherClose = body1Top > body2Top;
    bool is2CBB_Buy = isCurrentBullish && isHigherClose;

    // is 2CBB pattern Sell 
    bool isCurrentBearish = Close[i+1] < Open[i+1];
    bool isLowerClose = body1Bottom < body2Bottom;
    bool is2CBB_Sell = isCurrentBearish && isLowerClose;

    // is the price hitting the Major BBs in the last 2 Candles
    bool isHittingTheBBL1Down = (isHittingBB(i+1, BB_LONG1, false) || isHittingBB(i+2, BB_LONG1, false));
    bool isHittingTheBBL1Up = (isHittingBB(i+1, BB_LONG1, true) || isHittingBB(i+2, BB_LONG1, true));
    bool isHittingTheBBL2Down = (isHittingBB(i+1, BB_LONG2, false) || isHittingBB(i+2, BB_LONG2, false));
    bool isHittingTheBBL2Up = (isHittingBB(i+1, BB_LONG2, true) || isHittingBB(i+2, BB_LONG2, true));
    bool isHittingTheBBL3Down = (isHittingBB(i+1, BB_LONG3, false) || isHittingBB(i+2, BB_LONG3, false));
    bool isHittingTheBBL3Up = (isHittingBB(i+1, BB_LONG3, true) || isHittingBB(i+2, BB_LONG3, true));

    // is RSI Valid for entering LONG or SHORT
    bool isTheRSIValidForDown = (isRSIValid(i+1, false) || isRSIValid(i+2, false) );
    bool isTheRSIValidForUp = (isRSIValid(i+1, true) || isRSIValid(i+2, true) );

    // is the Short BB changing in values correctly
    bool isShortBBIncreasing = BB_small_1_Lower > BB_small_2_Lower;
    bool isShortBBDecreasing = BB_small_1_Upper < BB_small_2_Upper;

    // is the Close above or Below is correct based on the BB strategy
    bool isCloseAboveBB1 = Close[i+1] > BB_Long1_Lower;
    bool isCloseBelowBB1 = Close[i+1] < BB_Long1_Upper;
    bool isCloseAboveBB2 = Close[i+1] > BB_Long2_Lower;
    bool isCloseBelowBB2 = Close[i+1] < BB_Long2_Upper;
    bool isCloseAboveBB3 = Close[i+1] > BB_Long3_Lower;
    bool isCloseBelowBB3 = Close[i+1] < BB_Long3_Upper;

     // All Conditions Booleans
    bool isConditionBuyBB1 = isHittingTheBBL1Down && isCloseAboveBB1;
    bool isConditionSellBB1 = isHittingTheBBL1Up && isCloseBelowBB1;
    bool isConditionBuyBB2 = isHittingTheBBL2Down && isCloseAboveBB2;
    bool isConditionSellBB2 = isHittingTheBBL2Up && isCloseBelowBB2;
    bool isConditionBuyBB3 = isHittingTheBBL3Down && isCloseAboveBB3;
    bool isConditionSellBB3 = isHittingTheBBL3Up && isCloseBelowBB3;

    // final conditions
    bool conditionBuy = (isConditionBuyBB2 || isConditionBuyBB3) && isTheRSIValidForDown && isShortBBIncreasing && is2CBB_Buy;
    bool conditionSell = (isConditionSellBB2 || isConditionSellBB3) && isTheRSIValidForUp && isShortBBDecreasing && is2CBB_Sell;

    // final IF statement
    if(conditionBuy) {
      Buffer1[i] = Low[1+i];
      double TPandSL1[2];
      calcTPandSL(false, TPandSL1);
      double TP1 = TPandSL1[0];
      double SL1 = TPandSL1[1];
      openOrder(false, TP1, SL1);
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(conditionSell){
      Buffer2[i] = High[1+i];
      double TPandSL2[2];
      calcTPandSL(true, TPandSL2);
      double TP2 = TPandSL2[0];
      double SL2 = TPandSL2[1];
      openOrder(true, TP2, SL2);

    } else Buffer2[i] = EMPTY_VALUE;
  }
}