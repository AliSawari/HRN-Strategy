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
#property indicator_label1 "Buy 2C"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell 2C"

// my shit
const double XYFactor = 0.2;
const int X_LookBack = 10;
const int Y_LookBack = 3;
const double XYMultiplier = 1.3;
const double SL_ATR_Multiplier = 0.3;
const int Sharp_Lookback = 5;
const int Sharp_Multiplier = 2;
const double Proper_MA_Diff_Multiplier = 0.618;
const int MA1 = 20;
const int MA2 = 50;
const int MA3 = 200;
const int MA_OFFSET = 1;


//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
extern bool Audible_Alerts = true;
extern bool Push_Notifications = true;
double myPoint; //initialized in OnInit

void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = " | 2C Pattern ";
  if(type == "print") Print(message);
  else if(type == "error") Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | "+message);
  else if(type == "indicator") {
    Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message );
    if(Audible_Alerts) Alert(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);
    if(Push_Notifications) SendNotification(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);
  }
}



bool isDoublesEqual(double number1,double number2) { 
   if(NormalizeDouble(number1-number2,8)==0) return true;
   else return false;
} 


void calcXandY(bool isUpt, int candleIndex, double& results[]){
  
  double currentClose = iClose(Symbol(),PERIOD_CURRENT, candleIndex);
  int xCounter = 0;
  int yCounter = 0;
  double xTemp[];
  double yTemp[];
  ArrayResize(xTemp, X_LookBack);
  ArrayResize(yTemp, Y_LookBack);
  ArrayInitialize(xTemp, EMPTY_VALUE);
  ArrayInitialize(yTemp, EMPTY_VALUE);
  

  for(int i = candleIndex; i < (candleIndex + X_LookBack); i++){
    xTemp[xCounter] = isUpt ? iHigh(Symbol(),PERIOD_CURRENT, i) : iLow(Symbol(),PERIOD_CURRENT, i);
    xCounter++;
  }

  for(int x = candleIndex; x < (candleIndex + Y_LookBack); x++){
    yTemp[yCounter] = isUpt ? iLow(Symbol(),PERIOD_CURRENT, x) : iHigh(Symbol(),PERIOD_CURRENT, x);
    yCounter++;
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


bool isThereRoomToBreath(bool isUpt, int candleIndex){
  double XandYResults[2];
  ArrayInitialize(XandYResults, EMPTY_VALUE);
  calcXandY(isUpt, candleIndex, XandYResults);
  double X = XandYResults[0];
  double Y = XandYResults[1];
  int xCounter = 0;
  int yCounter = 0;
  // double currentClose = iClose(Symbol(),PERIOD_CURRENT, 1);
  double currentHigh = iHigh(Symbol(), PERIOD_CURRENT, candleIndex);
  double currentLow = iLow(Symbol(), PERIOD_CURRENT, candleIndex);
  double xTemp[];
  ArrayResize(xTemp, X_LookBack);
  ArrayInitialize(xTemp, EMPTY_VALUE);

  for(int i = candleIndex; i < (candleIndex + X_LookBack); i++){
    xTemp[xCounter] = isUpt ? iHigh(Symbol(),PERIOD_CURRENT, i) : iLow(Symbol(), PERIOD_CURRENT, i);
    xCounter++;
  }

  int X_Max_i = ArrayMaximum(xTemp, WHOLE_ARRAY, 0);
  int X_Min_i = ArrayMinimum(xTemp, WHOLE_ARRAY, 0);

  bool isAlreadyHit = isUpt ? isDoublesEqual(xTemp[X_Max_i], currentHigh) : isDoublesEqual(currentLow, xTemp[X_Min_i]) ;

  if(isAlreadyHit) return false;
  else if(X < Y && X >= ( XYFactor * Y) ) return true;
  else if( X >= Y) return true;
  else return false;
}


void getOHLC(int candleIndex, double& results[]){
  string S = Symbol();
  double O = iOpen(S, PERIOD_CURRENT, candleIndex);
  double H = iHigh(S, PERIOD_CURRENT, candleIndex);
  double L = iLow(S, PERIOD_CURRENT, candleIndex);
  double C = iClose(S, PERIOD_CURRENT, candleIndex);
  ArrayFill(results, 0, 1, O);
  ArrayFill(results, 1, 1, H);
  ArrayFill(results, 2, 1, L);
  ArrayFill(results, 3, 1, C);
}



bool isNotSharpCandle(int candleIndex){
  int L = Sharp_Lookback;
  string S = Symbol();
  double carrier = 0;
  double OHLC_1[4];
  double OHLC_2[4];
  double OHLC_3[4];
  getOHLC(candleIndex, OHLC_1);
  getOHLC((candleIndex + 1), OHLC_2);
  getOHLC((candleIndex + 2), OHLC_3);
  for(int i = candleIndex; i < (candleIndex + L); i++){
    double h = iHigh(S, PERIOD_CURRENT, i);
    double l = iLow(S, PERIOD_CURRENT, i);
    carrier += (h - l);
  }

  double average = carrier / L;
  double diff1 = OHLC_1[1] - OHLC_1[2];
  double diff2 = OHLC_2[1] - OHLC_2[2];
  double diff3 = OHLC_3[1] - OHLC_3[2];
  double mult = (average * Sharp_Multiplier);
  bool isSharp = diff1 > mult || diff2 > mult || diff3 > mult;
  return !isSharp;
}


bool isHittingMA(int candleIndex, int MA){
  double theMA = iMA(NULL, PERIOD_CURRENT, MA, 0, MODE_SMA, PRICE_CLOSE, candleIndex);
  double theMAOffset = iMA(NULL, PERIOD_CURRENT, (MA - MA_OFFSET), 0, MODE_SMA, PRICE_CLOSE, candleIndex);
  string S = Symbol();
  double OHLC[4];
  getOHLC(candleIndex, OHLC);
  bool isH = (OHLC[1] >= theMA && theMA >= OHLC[2] ) || (OHLC[1] >= theMAOffset && theMAOffset >= OHLC[2]);
  return isH;
}


bool isNotHittingAllMAs(int candleIndex){
  int before = candleIndex + 1;
  int third = candleIndex + 2;
  bool is1HittingMA1 = isHittingMA(candleIndex, MA1);
  bool is1HittingMA2 = isHittingMA(candleIndex, MA2);
  bool is1HittingMA3 = isHittingMA(candleIndex, MA3);
  bool is2HittingMA1 = isHittingMA(before, MA1);
  bool is2HittingMA2 = isHittingMA(before, MA2);
  bool is2HittingMA3 = isHittingMA(before, MA3);
  bool is3HittingMA1 = isHittingMA(third, MA1);
  bool is3HittingMA2 = isHittingMA(third, MA2);
  bool is3HittingMA3 = isHittingMA(third, MA3);
  bool isNot = !(is1HittingMA1 && is1HittingMA2 && is1HittingMA3) && !(is2HittingMA1 && is2HittingMA2 && is2HittingMA3) && !(is3HittingMA1 && is3HittingMA2 && is3HittingMA3);
  return isNot;
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
                const int& spread[]) {
  int limit = rates_total - prev_calculated;
  //--- counting from 0 to rates_total
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  //--- initial zero
  if(prev_calculated < 1){
    ArrayInitialize(Buffer1, EMPTY_VALUE);
    ArrayInitialize(Buffer2, EMPTY_VALUE);
  }
  else limit++;
  
  //--- main loop
  for(int i = limit-1; i >= 0; i--) {
    if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation
    // Main MAs & RSI
    double MA20_1 = iMA(NULL, PERIOD_CURRENT, MA1, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA20_2 = iMA(NULL, PERIOD_CURRENT, MA1, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA50_1 = iMA(NULL, PERIOD_CURRENT, MA2, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA50_2 = iMA(NULL, PERIOD_CURRENT, MA2, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double MA200_1 = iMA(NULL, PERIOD_CURRENT, MA3, 0, MODE_SMA, PRICE_CLOSE, i+1);
    double MA200_2 = iMA(NULL, PERIOD_CURRENT, MA3, 0, MODE_SMA, PRICE_CLOSE, i+2);
    double RSI = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 1+i);
    double ATR = iATR(NULL, PERIOD_CURRENT, 14, i+1);
    // MA comparison & RSI Validation
    bool isUptrend = MA20_1 > MA50_1 && MA50_1 > MA200_1 && MA20_2 > MA50_2 && MA50_2 > MA200_2;
    bool isDowntrend = MA20_1 < MA50_1 && MA50_1 < MA200_1 && MA20_2 < MA50_2 && MA50_2 < MA200_2;
    bool RSIValidationUptrend = RSI < 70;
    bool RSIValidationDowntrend = RSI > 30;
    // MAs increasing in value
    bool isMAsIncreasing = MA20_1 > MA20_2 && MA50_1 > MA50_2;
    bool isMAsDecreasing = MA20_1 < MA20_2 && MA50_1 < MA50_2;
    // is either of the candles are in contact with the MA (approximation -2), in order to detect a Pullback on the MA
    // bool isHitting1 = (MA20_1 <= High[i+1] && MA20_1 >= Low[i+1]) || (MA18_1 <= High[i+1] && MA18_1 >= Low[i+1]);
    // bool isHitting2 = (MA20_2 <= High[i+2] && MA20_2 >= Low[i+2]) || (MA18_2 <= High[i+2] && MA18_2 >= Low[i+2]);
    bool isHittingMA20 = isHittingMA(i+1, 20) || isHittingMA(i+2, 20);
    // bool isHitting3 = (MA50_1 <= High[i+1] && MA50_1 >= Low[i+1]) || (MA48_1 <= High[i+1] && MA48_1 >= Low[i+1]);
    // bool isHitting4 = (MA50_2 <= High[i+2] && MA50_2 >= Low[i+2]) || (MA48_2 <= High[i+2] && MA48_2 >= Low[i+2]);
    bool isHittingMA50 = isHittingMA(i+1, 50)  || isHittingMA(i+2, 50);

    bool isNotSharp = isNotSharpCandle(i+1);
    // bool isProperMA = isProperMADistance(MA1, MA2, MA3);
    bool isNotHittingAll = isNotHittingAllMAs(i+1);
    bool isThereRoomUp = isThereRoomToBreath(true, i+1);
    bool isThereRoomDown = isThereRoomToBreath(false, i+1);

    // All Indicators Conditions Boolean
    bool isConditionMetUptrend = isUptrend && isMAsIncreasing && RSIValidationUptrend && isThereRoomUp && isNotSharp && isNotHittingAll;
    bool isConditionMetDowntrend = isDowntrend && isMAsDecreasing && RSIValidationDowntrend && isThereRoomDown && isNotSharp && isNotHittingAll;

    // is 2 Candle pattern Buy 
    bool isPrevBear = Open[i+2] > Close[i+2];
    bool isCurrentBull = Open[i+1] < Close[i+1];
    bool isHigherClose = Close[i+1] > MathMax(Open[i+2], Close[i+2]);
    bool isHigherShadow = High[i+1] >= High[i+2]; 
    float body1B = MathAbs(Close[i+1] - Open[i+1]);
    float body2B = MathAbs(Close[i+2] - Open[i+2]);
    float upperShadow1 = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    float upperShadow2 = High[i+2] - MathMax(Open[i+2], Close[i+2]);
    bool isUpperShadowsSmallerThanBodies = upperShadow1 < body1B && upperShadow2 < body2B;
    bool isCloseAbove20 = Close[i+1] > MA20_1;
    bool isCloseAbove50 = Close[i+1] > MA50_1;
    bool is2CPatternBuy = isPrevBear && isCurrentBull && isHigherClose && isHigherShadow;
    bool is2CBuy20 = is2CPatternBuy && isCloseAbove20;
    bool is2CBuy50 = is2CPatternBuy && isCloseAbove50;
    // is 2 Candle pattern Sell
    bool isPrevBull = Open[i+2] < Close[i+2];
    bool isCurrentBear = Open[i+1] > Close[i+1];
    bool isLowerClose = Close[i+1] < MathMin(Open[i+2], Close[i+2]);
    bool isLowerShadow = Low[i+1] <= Low[i+2];
    float body1S = MathAbs(Close[i+1] - Open[i+1]);
    float body2S = MathAbs(Close[i+2] - Open[i+2]);
    float lowerShadow1 = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    float lowerShadow2 = MathMin(Open[i+2], Close[i+2]) - Low[i+2];
    bool isLowerShadowsSmallerThanBodies = lowerShadow1 < body1S && lowerShadow2 < body2S;
    bool isCloseBelow20 = Close[i+1] < MA20_1;
    bool isCloseBelow50 = Close[i+1] < MA50_1;
    bool is2CPatternSell = isPrevBull && isCurrentBear && isLowerClose && isLowerShadow;
    bool is2CSell20 = is2CPatternSell && isCloseBelow20;
    bool is2CSell50 = is2CPatternSell && isCloseBelow50;


    // final conditions
    bool conditionUptrend20 = isConditionMetUptrend && isHittingMA20 && is2CBuy20;
    bool conditionUptrend50 = isConditionMetUptrend && isHittingMA50 && is2CBuy50;
    bool conditionDowntrend20 = isConditionMetDowntrend && isHittingMA20 && is2CSell20;
    bool conditionDowntrend50 = isConditionMetDowntrend && isHittingMA50 && is2CSell50;

    // arrow place
    double distance = 0.3;
    double arrowMultUp = (Low[i+1] - (distance * ATR));
    double arrowMultDown = (High[i+1] + (distance * ATR));

    if(conditionUptrend20 || conditionUptrend50) {
      Buffer1[i+1] = arrowMultUp;
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", conditionUptrend20 ? "Buy 2C-MA20" : "Buy 2C-MA50"); time_alert = Time[0];
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(conditionDowntrend20 || conditionDowntrend50){
      Buffer2[i+1] = arrowMultDown;
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", conditionDowntrend20 ? "Sell 2C-MA20" : "Sell 2C-MA50"); time_alert = Time[0];
    } else Buffer2[i] = EMPTY_VALUE;

  }

  return(rates_total);
}
