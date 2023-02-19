#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description ""

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy HRN"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell HRN"


//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
extern bool Audible_Alerts = true;
extern bool Push_Notifications = true;
double myPoint; //initialized in OnInit

// my shit
extern double XYFactor = 0.2;
extern int X_LookBack = 10;
extern int Y_LookBack = 3;
extern int XYMultiplier = 2;


bool isDoublesEqual(double number1,double number2) { 
   if(NormalizeDouble(number1-number2,8)==0) return true;
   else return false;
} 



string getCorrectMSG(bool uptrend, int context){
    string msg;
    if(uptrend){
      if(context == 8) msg = "Buy HRN MA8";
      else if(context == 20) msg = "Buy HRN MA20";
      else if(context == 50) msg = "Buy HRN MA50";
    } else {
      if(context == 8) msg = "Sell HRN MA8";
      else if(context == 20) msg = "Sell HRN MA20";
      else if(context == 50) msg = "Sell HRN MA50";
    }

    return msg;
}


void calcXandY(bool isUpt, double& results[]){
  
  double currentClose = iClose(Symbol(),PERIOD_CURRENT, 1);
  int xCounter = 0;
  int yCounter = 0;

  double xTemp[];
  double yTemp[];
  ArrayResize(xTemp, X_LookBack);
  ArrayResize(yTemp, Y_LookBack);
  ArrayInitialize(xTemp, EMPTY_VALUE);
  ArrayInitialize(yTemp, EMPTY_VALUE);
  

  for(int i = 1; i <= (X_LookBack); i++){
    xTemp[i-1] = isUpt ? iHigh(Symbol(),PERIOD_CURRENT, i) : iLow(Symbol(),PERIOD_CURRENT, i);
    // xCounter++;
  }

  for(int x = 1; x <= (Y_LookBack); x++){
    yTemp[x-1] = isUpt ? iLow(Symbol(),PERIOD_CURRENT, x) : iHigh(Symbol(),PERIOD_CURRENT, x);
    // yCounter++;
  }

  int X_Max_i = ArrayMaximum(xTemp, WHOLE_ARRAY, 0);
  int X_Min_i = ArrayMinimum(xTemp, WHOLE_ARRAY, 0);
  int Y_Max_i = ArrayMaximum(yTemp, WHOLE_ARRAY, 0);
  int Y_Min_i = ArrayMinimum(yTemp, WHOLE_ARRAY, 0);

  double X = isUpt ? MathAbs(xTemp[X_Max_i] - currentClose) : MathAbs(currentClose - xTemp[X_Min_i]);
  double Y = isUpt ? MathAbs( currentClose - yTemp[Y_Min_i] ) : MathAbs( yTemp[Y_Max_i] - currentClose);

  
  ArrayFill(results, 0, 1, X);
  ArrayFill(results, 1, 1, Y);

  // results[0] = X;
  // results[1] = Y;

}




bool isThereRoomToBreath(bool isUpt){
  double XandYResults[2];
  ArrayInitialize(XandYResults, EMPTY_VALUE);
  calcXandY(isUpt, XandYResults);
  double X = XandYResults[0];
  double Y = XandYResults[1];
  double currentHigh = iHigh(Symbol(), PERIOD_CURRENT, 1);
  double currentLow = iLow(Symbol(), PERIOD_CURRENT, 1);
  double xTemp[];
  ArrayResize(xTemp, X_LookBack);
  ArrayInitialize(xTemp, EMPTY_VALUE);

  for(int i = 1; i <= X_LookBack; i++){
    xTemp[i-1] = isUpt ? iHigh(Symbol(), PERIOD_CURRENT, i) : iLow(Symbol(),PERIOD_CURRENT, i);
  }

  int X_Max_i = ArrayMaximum(xTemp, WHOLE_ARRAY, 0);
  int X_Min_i = ArrayMinimum(xTemp, WHOLE_ARRAY, 0);

  bool isAlreadyHit = isUpt ? isDoublesEqual(xTemp[X_Max_i], currentHigh) : isDoublesEqual(currentLow, xTemp[X_Min_i]) ;

  if(isAlreadyHit) return false;
  else if(X < Y && X >= ( XYFactor * Y) ) return true;
  else if( X >= Y) return true;
  else return false;
}



void calcTPandSL(bool isUpt, double& results[]){
  double XandYResults[2];
  ArrayInitialize(XandYResults, EMPTY_VALUE);
  calcXandY(isUpt, XandYResults);
  double X = XandYResults[0];
  double Y = XandYResults[1];
  double TP;
  double SL;
  double limit = (Y * XYMultiplier);
  double currentClose = iClose(Symbol(),PERIOD_CURRENT, 1);

  if(X < Y && X >= ( XYFactor * Y) ){
    if(isUpt){
			TP = currentClose + Y;
			SL = currentClose - Y;
    } else {
      TP = currentClose - Y;
			SL = currentClose + Y;
    }
  } else if( X >= Y) {
    if(X < limit) limit = X;
    if(isUpt){
			TP = currentClose + limit;
			SL = currentClose - limit;
    } else {
      TP = currentClose - limit;
			SL = currentClose + limit;
    }
  }

  ArrayFill(results, 0, 1, TP);
  ArrayFill(results, 1, 1, SL);
  // results[0] = TP;
  // results[1] = SL;
}



void openOrder(bool upt, double TP, double SL, string text){
  int rand = MathRand();
  string msg = upt ? " Buy Order " + text : " Sell order " + text ;
  PrintFormat("About to %s with TP: %e and SL: %e", msg, TP, SL);
  if(upt) OrderSend(Symbol(), OP_BUY, 0.01, Ask, 1, SL, TP, msg, rand, 0, clrGreen);
  else OrderSend(Symbol(), OP_SELL, 0.01, Bid, 1, SL, TP, msg, rand, 0, clrRed);
  OrderPrint();
}



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {   
  IndicatorBuffers(2);
  SetIndexBuffer(0, Buffer1);
  SetIndexEmptyValue(0, EMPTY_VALUE);
  SetIndexArrow(0, 241);
  SetIndexBuffer(1, Buffer2);
  SetIndexEmptyValue(1, EMPTY_VALUE);
  SetIndexArrow(1, 242);
  //initialize myPoint
  myPoint = Point();
  if(Digits() == 5 || Digits() == 3){
    myPoint *= 10;
  }
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

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


void OnTick() {
  if(IsNewCandle()){
    //--- counting from 0 to rates_total
    ArraySetAsSeries(Buffer1, true);
    ArraySetAsSeries(Buffer2, true);
  //--- initial zero

    int i = 0;
    // Main MAs & RSI
    double MA8_1 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA8_2 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA8_3 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+3);
    double MA20_1 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA20_2 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA20_3 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+3);
    double MA50_1 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA50_2 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA50_3 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+3);
    double RSI = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 1+i);
    // Approximation MAs for Better PB Detection
    double MA7_1 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA7_2 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA7_3 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE, i+3);
    double MA18_1 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA18_2 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA18_3 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+3);
    double MA48_1 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA48_2 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA48_3 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+3);
    // MA comparison & RSI Validation
    bool isUptrend = MA8_1 > MA20_1 && MA20_1 > MA50_1 && MA8_2 > MA20_2 && MA20_2 > MA50_2 && MA8_3 > MA20_3 && MA20_3 > MA50_3;
    bool isUptrendFor50 = MA20_1 > MA50_1 && MA20_2 > MA50_2 && MA20_3 > MA50_3;
    bool isDowntrend = MA8_1 < MA20_1 && MA20_1 < MA50_1 && MA8_2 < MA20_2 && MA20_2 < MA50_2 && MA8_3 < MA20_3 && MA20_3 < MA50_3;
    bool isDowntrendFor50 = MA20_1 < MA50_1 && MA20_2 < MA50_2 && MA20_3 < MA50_3;
    bool RSIValidationUptrend = RSI < 70;
    bool RSIValidationDowntrend = RSI > 30;
    // MAs increasing in value
    bool isMAsIncreasing = MA8_1 > MA8_2 && MA8_2 > MA8_3 && MA20_1 > MA20_2 && MA20_2 > MA20_3 && MA50_1 > MA50_2 && MA50_2 > MA50_3;
    bool isMAsIncreasingFor50 = MA20_1 > MA20_2 && MA20_2 > MA20_3 && MA50_1 > MA50_2 && MA50_2 > MA50_3;
    bool isMAsDecreasing = MA8_1 < MA8_2 && MA8_2 < MA8_3 && MA20_1 < MA20_2 && MA20_2 < MA20_3 && MA50_1 < MA50_2 && MA50_2 < MA50_3;
    bool isMAsDecreasingFor50 = MA20_1 < MA20_2 && MA20_2 < MA20_3 && MA50_1 < MA50_2 && MA50_2 < MA50_3;
    // is either of the candles are in contact with the MA (approximation -2), in order to detect a Pullback on the MA
    bool isHitting1 = (MA8_1 <= High[i+1] && MA8_1 >= Low[i+1]) || (MA7_1 <= High[i+1] && MA7_1 >= Low[i+1]);
    bool isHitting2 = (MA8_2 <= High[i+2] && MA8_2 >= Low[i+2]) || (MA7_2 <= High[i+2] && MA7_2 >= Low[i+2]);
    bool isHitting3 = (MA8_3 <= High[i+3] && MA8_3 >= Low[i+3]) || (MA7_3 <= High[i+3] && MA7_3 >= Low[i+3]);
    bool isHittingMA8 = isHitting1 || isHitting2 || isHitting3;
    bool isHitting4 = (MA20_1 <= High[i+1] && MA20_1 >= Low[i+1]) || (MA18_1 <= High[i+1] && MA18_1 >= Low[i+1]);
    bool isHitting5 = (MA20_2 <= High[i+2] && MA20_2 >= Low[i+2]) || (MA18_2 <= High[i+2] && MA18_2 >= Low[i+2]);
    bool isHitting6 = (MA20_3 <= High[i+3] && MA20_3 >= Low[i+3]) || (MA18_3 <= High[i+3] && MA18_3 >= Low[i+3]);
    bool isHittingMA20 = isHitting4 || isHitting5 || isHitting6;
    bool isHitting7 = (MA50_1 <= High[i+1] && MA50_1 >= Low[i+1]) || (MA48_1 <= High[i+1] && MA48_1 >= Low[i+1]);
    bool isHitting8 = (MA50_2 <= High[i+2] && MA50_2 >= Low[i+2]) || (MA48_2 <= High[i+2] && MA48_2 >= Low[i+2]);
    bool isHitting9 = (MA50_3 <= High[i+3] && MA50_3 >= Low[i+3]) || (MA48_3 <= High[i+3] && MA48_3 >= Low[i+3]);
    bool isHittingMA50 = isHitting7 || isHitting8 || isHitting9;

    // All Indicators Conditions Boolean
    bool isConditionMetUptrend = isUptrend && isMAsIncreasing && RSIValidationUptrend && isThereRoomToBreath(true);
    bool isConditionMetUptrendFor50 = isUptrendFor50 && isMAsIncreasingFor50 && RSIValidationUptrend && isThereRoomToBreath(true);
    bool isConditionMetDowntrend = isDowntrend && isMAsDecreasing && RSIValidationDowntrend && isThereRoomToBreath(false);
    bool isConditionMetDowntrendFor50 = isDowntrendFor50 && isMAsDecreasingFor50 && RSIValidationDowntrend && isThereRoomToBreath(false);


    // Shared Variables
    double body1 = MathAbs(Close[i+1] - Open[i+1]);
    double body2 = MathAbs(Close[i+2] - Open[i+2]);
    double upperShadow1 = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    double upperShadow2 = High[i+2] - MathMax(Open[i+2], Close[i+2]);
    double lowerShadow1 = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    double lowerShadow2 = MathMin(Open[i+2], Close[i+2]) - Low[i+2];
    bool isEngulfingShadow = High[i+1] >= High[i+2] && Low[i+1] <= Low[i+2];

    // is HRN Pattern Buy
    bool is3rdBear_HRNBUY = Open[i+3] > Close[i+3];
    bool isPrevBear_HRNBUY = Open[i+2] > Close[i+2];
    bool isCurrentBull_HRNBUY = Open[i+1] < Close[i+1];
    bool isOHCL3BiggerThan2_HRNBUY = MathMax(Open[i+3],Close[i+3]) > MathMax(Open[i+2],Close[i+2]) && MathMin(Open[i+3],Close[i+3]) > MathMin(Open[i+2],Close[i+2]) && High[i+3] > High[i+2] && Low[i+3] > Low[i+2];
    bool isHigherClose_HRNBUY = Close[i+1] >= MathMax(Open[i+2],Close[i+2]);
    bool isHigherOpen_HRNBUY = Open[i+1] >= MathMin(Open[i+2],Close[i+2]);
    bool isHigherShadow_HRNBUY = High[i+1] >= High[i+2];
    bool isUpperShadowsSmallerThanBodies_HRN = upperShadow1 < body1 && upperShadow2 < body2;
    bool isCloseAbove8_HRN = Close[i+1] > MA8_1;
    bool isCloseAbove20_HRN = Close[i+1] > MA20_1;
    bool isCloseAbove50_HRN = Close[i+1] > MA50_1;
    bool isHRNBuyPattern = is3rdBear_HRNBUY && isPrevBear_HRNBUY && isCurrentBull_HRNBUY && isOHCL3BiggerThan2_HRNBUY && isHigherClose_HRNBUY && isHigherOpen_HRNBUY && isHigherShadow_HRNBUY && isUpperShadowsSmallerThanBodies_HRN;
    bool isHRNBuy8 = isHRNBuyPattern && isCloseAbove8_HRN;
    bool isHRNBuy20 = isHRNBuyPattern && isCloseAbove20_HRN;
    bool isHRNBuy50 = isHRNBuyPattern && isCloseAbove50_HRN;

    bool conditionUptrend8HRN = isConditionMetUptrend && isHittingMA8 && isHRNBuy8;
    bool conditionUptrend20HRN = isConditionMetUptrend && isHittingMA20 && isHRNBuy20;
    bool conditionUptrend50HRN = isConditionMetUptrendFor50 && isHittingMA50 && isHRNBuy50;

    bool isHRNBuy = conditionUptrend8HRN || conditionUptrend20HRN || conditionUptrend50HRN;
  
      // is HRN Pattern Sell
    bool is3rdBull_HRNSELL = Open[i+3] < Close[i+3];
    bool isPrevBull_HRNSELL = Open[i+2] < Close[i+2];
    bool isCurrentBear_HRNSELL = Open[i+1] > Close[i+1];
    bool isOHCL3LowerThan2_HRN = MathMax(Open[i+3],Close[i+3]) < MathMax(Open[i+2],Close[i+2]) && MathMin(Open[i+3],Close[i+3]) < MathMin(Open[i+2],Close[i+2]) && High[i+3] < High[i+2] && Low[i+3] < Low[i+2];
    bool isLowerClose_HRNSELL = Close[i+1] <= MathMin(Open[i+2],Close[i+2]);
    bool isLowerOpen_HRNSELL = Open[i+1] <= MathMax(Open[i+2],Close[i+2]);
    bool isLowerShadow_HRNSELL = Low[i+1] <= Low[i+2];
    bool isLowerShadowsSmallerThanBodies_HRN = lowerShadow1 < body1 && lowerShadow2 < body2;
    bool isCloseBelow8_HRN = Close[i+1] < MA8_1;
    bool isCloseBelow20_HRN = Close[i+1] < MA20_1;
    bool isCloseBelow50_HRN = Close[i+1] < MA50_1;
    bool isHRNSellPattern = is3rdBull_HRNSELL && isPrevBull_HRNSELL && isCurrentBear_HRNSELL && isOHCL3LowerThan2_HRN && isLowerClose_HRNSELL && isLowerOpen_HRNSELL && isLowerShadow_HRNSELL && isLowerShadowsSmallerThanBodies_HRN;
    bool isHRNSell8 = isHRNSellPattern && isCloseBelow8_HRN;
    bool isHRNSell20 = isHRNSellPattern && isCloseBelow20_HRN;
    bool isHRNSell50 = isHRNSellPattern && isCloseBelow50_HRN;
    // final conditions
    bool conditionDowntrend8HRN = isConditionMetDowntrend && isHittingMA8 && isHRNSell8;
    bool conditionDowntrend20HRN = isConditionMetDowntrend && isHittingMA20 && isHRNSell20;
    bool conditionDowntrend50HRN = isConditionMetDowntrendFor50 && isHittingMA50 && isHRNSell50;
    bool isHRNSell = conditionDowntrend8HRN || conditionDowntrend20HRN || conditionDowntrend50HRN;


    // is Engulfing Pattern Buy
    bool isPrevBear_ENG = Open[i+2] > Close[i+2];
    bool isCurrentBull_ENG = Open[i+1] < Close[i+1];
    bool isEngulfingBodyB_ENG = Close[i+1] >= Open[i+2] && Open[i+1] <= Close[i+2];
    bool isUpperShadowsSmallerThanBodies_ENG = upperShadow1 < body1 && upperShadow2 < body2;
    bool isCloseAbove8_ENG = Close[i+1] > MA8_1;
    bool isCloseAbove20_ENG = Close[i+1] > MA20_1;
    bool isCloseAbove50_ENG = Close[i+1] > MA50_1;
    bool isEngulfingBuyPattern = isPrevBear_ENG && isCurrentBull_ENG && isEngulfingBodyB_ENG && isEngulfingShadow && isUpperShadowsSmallerThanBodies_ENG;
    bool isEngulfingBuy8 = isEngulfingBuyPattern && isCloseAbove8_ENG;
    bool isEngulfingBuy20 = isEngulfingBuyPattern && isCloseAbove20_ENG;
    bool isEngulfingBuy50 = isEngulfingBuyPattern && isCloseAbove50_ENG;

    bool conditionUptrend8_ENG = isConditionMetUptrend && isHittingMA8 && isEngulfingBuy8;
    bool conditionUptrend20_ENG = isConditionMetUptrend && isHittingMA20 && isEngulfingBuy20;
    bool conditionUptrend50_ENG = isConditionMetUptrendFor50 && isHittingMA50 && isEngulfingBuy50;

    bool isEngulfingBuy = conditionUptrend8_ENG || conditionUptrend20_ENG || conditionUptrend50_ENG;


    // is Engulfing Pattern Sell
    bool isPrevBull_ENG = Open[i+2] < Close[i+2];
    bool isCurrentBear_ENG = Open[i+1] > Close[i+1];
    bool isEngulfingBodyS_ENG = Close[i+1] <= Open[i+2] && Open[i+1] >= Close[i+2];
    bool isLowerShadowsSmallerThanBodies_ENG = lowerShadow1 < body1 && lowerShadow2 < body2;
    bool isCloseBelowMA8_ENG = Close[i+1] < MA8_1;
    bool isCloseBelowMA20_ENG = Close[i+1] < MA20_1;
    bool isCloseBelowMA50_ENG = Close[i+1] < MA50_1;
    bool isEngulfingSellPattern = isPrevBull_ENG && isCurrentBear_ENG && isEngulfingBodyS_ENG && isEngulfingShadow && isLowerShadowsSmallerThanBodies_ENG;
    bool isEngulfingSell8 = isEngulfingSellPattern && isCloseBelowMA8_ENG;
    bool isEngulfingSell20 = isEngulfingSellPattern && isCloseBelowMA20_ENG;
    bool isEngulfingSell50 = isEngulfingSellPattern && isCloseBelowMA50_ENG;
    bool conditionDowntrend8_ENG = isConditionMetDowntrend && isHittingMA8 && isEngulfingSell8;
    bool conditionDowntrend20_ENG = isConditionMetDowntrend && isHittingMA20 && isEngulfingSell20;
    bool conditionDowntrend50_ENG = isConditionMetDowntrendFor50 && isHittingMA50 && isEngulfingSell50;

    bool isEngulfingSell = conditionDowntrend8_ENG || conditionDowntrend20_ENG || conditionDowntrend50_ENG;

    // is Hammer Pattern  Buy
    bool isPrevBear_Ham = Close[i+2] < Open[i+2];
    bool isBodyBiggerThanUpperShadow_Ham = body1 >= upperShadow1;
    bool isLowerShadowTwiceTheBody_Ham = lowerShadow1 >= (3 * body2);
    bool isCloseLowerThan_Ham = MathMax(Open[i+1], Close[i+1]) < MathMax(Open[i+2], Close[i+2]);
    bool isShadowTrailingBelow = Low[i+1] < Low[i+2];
    bool isPrevNotHammerB = (body2 * 2) >= upperShadow2;
    bool isFiftyPercentBelowMA8 = (Low[i+1] + ( 0.5 * lowerShadow1 )) <= MA8_1;
    bool isFiftyPercentBelowMA20 = (Low[i+1] + ( 0.5 * lowerShadow1 )) <= MA20_1;
    bool isFiftyPercentBelowMA50 = (Low[i+1] + ( 0.5 * lowerShadow1 )) <= MA50_1;
    bool isCloseAboveMA8_Ham = MathMax(Open[i+1], Close[i+1]) >= MA8_1;
    bool isCloseAboveMA20_Ham = MathMax(Open[i+1], Close[i+1]) >= MA20_1;
    bool isCloseAboveMA50_Ham = MathMax(Open[i+1], Close[i+1]) >= MA50_1;
    bool isHammerPatternBuy = isPrevBear_Ham && isBodyBiggerThanUpperShadow_Ham && isLowerShadowTwiceTheBody_Ham && isCloseLowerThan_Ham && isShadowTrailingBelow && isPrevNotHammerB;
    bool isHammerBuy8 = isHammerPatternBuy && isCloseAboveMA8_Ham && isFiftyPercentBelowMA8;
    bool isHammerBuy20 = isHammerPatternBuy && isCloseAboveMA20_Ham && isFiftyPercentBelowMA20;
    bool isHammerBuy50 = isHammerPatternBuy && isCloseAboveMA50_Ham && isFiftyPercentBelowMA50;

    bool conditionUptrend8_Ham = isConditionMetUptrend && isHittingMA8 && isHammerBuy8;
    bool conditionUptrend20_Ham = isConditionMetUptrend && isHittingMA20 && isHammerBuy20;
    bool conditionUptrend50_Ham = isConditionMetUptrendFor50 && isHittingMA50 && isHammerBuy50;

    bool isHammerBuy = conditionUptrend8_Ham || conditionUptrend20_Ham || conditionUptrend50_Ham;


    // is Hammer Pattern  Sell
    bool isPrevBull_Ham = Close[i+2] > Open[i+2];
    bool isBodyBiggerThanLowerShadow = body1 >= lowerShadow1;
    bool isUpperShadowTwiceTheBody = upperShadow1 >= (3 * body1);
    bool isCloseAboveThan_Ham = MathMin(Open[i+1], Close[i+1]) > MathMin(Open[i+2], Close[i+2]);
    bool isShadowTrailingAbove = High[i+1] > High[i+2];
    bool isPrevNotHammerS = (body2 * 2) >= lowerShadow2;
    bool isFiftyPercentAboveMA8 = (High[i+1] - (0.5 * upperShadow1)) >= MA8_1;
    bool isFiftyPercentAboveMA20 = (High[i+1] - (0.5 * upperShadow1)) >= MA20_1;
    bool isFiftyPercentAboveMA50 = (High[i+1] - (0.5 * upperShadow1)) >= MA50_1;
    bool isCloseBelowMA8_Ham = MathMin(Open[i+1], Close[i+1]) <= MA8_1;
    bool isCloseBelowMA20_Ham = MathMin(Open[i+1], Close[i+1]) <= MA20_1;
    bool isCloseBelowMA50_Ham = MathMin(Open[i+1], Close[i+1]) <= MA50_1;
    bool isHammerPatternSell = isPrevBull_Ham && isBodyBiggerThanLowerShadow && isUpperShadowTwiceTheBody && isShadowTrailingAbove && isCloseAboveThan_Ham && isPrevNotHammerS;
    bool isHammerSell8 = isHammerPatternSell && isCloseBelowMA8_Ham && isFiftyPercentAboveMA8;
    bool isHammerSell20 = isHammerPatternSell && isCloseBelowMA20_Ham && isFiftyPercentAboveMA20;
    bool isHammerSell50 = isHammerPatternSell && isCloseBelowMA50_Ham && isFiftyPercentAboveMA50;

    bool conditionDowntrend8_Ham = isConditionMetDowntrend && isHittingMA8 && isHammerSell8;
    bool conditionDowntrend20_Ham = isConditionMetDowntrend && isHittingMA20 && isHammerSell20;
    bool conditionDowntrend50_Ham = isConditionMetDowntrendFor50 && isHittingMA50 && isHammerSell50;

    bool isHammerSell = conditionDowntrend8_Ham || conditionDowntrend20_Ham || conditionDowntrend50_Ham;



    bool isLongCondition = isHRNBuy || isEngulfingBuy || isHammerBuy;
    bool isSellCondition = isHRNSell || isEngulfingSell || isHammerSell;

    string type = "";
    if(isHRNBuy || isHRNSell) type = "HRN";
    if(isEngulfingBuy || isEngulfingSell) type = "Engulfing";
    if(isHammerBuy || isHammerSell) type = "Hammer";
    

    if(isLongCondition) {
      PrintFormat("Spotted %s Pattern", type);
      Buffer1[i] = Low[1+i];
      double TPandSL1[2];
      ArrayInitialize(TPandSL1, EMPTY_VALUE);
      calcTPandSL(true, TPandSL1);
      double TP1 = TPandSL1[0];
      double SL1 = TPandSL1[1];
      openOrder(true, TP1, SL1, type);
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(isSellCondition){
      PrintFormat("Spotted %s Pattern", type);
      Buffer2[i] = High[1+i];
      double TPandSL2[2];
      ArrayInitialize(TPandSL2, EMPTY_VALUE);
      calcTPandSL(false, TPandSL2);
      double TP2 = TPandSL2[0];
      double SL2 = TPandSL2[1];
      openOrder(false, TP2, SL2, type);

    } else Buffer2[i] = EMPTY_VALUE;


  }
}
