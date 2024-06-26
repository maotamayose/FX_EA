#define ACCOUNT_NUMBER 0
#define EXPIRY_DATE "0"
//--------------------------------------------------------------------------------------------//

input string orderSetting = "---------------注文設定---------------"; // ▼注文
input double pipsstart = 5.0;          // 最初のエントリー位置pips
input double pipsToMove = 10.0;        // 上下のpipsの距離
input double profitTargetpips = 5.0;   // 利益を確定するための目標獲得損益
input int slippagePips = 2;            // スリッページ
input double bairitu = 0.8;            // 倍率

input string otherMargin = "";         //
input string otherSetting = "---------------その他設定---------------"; // ▼その他
input int interval_ALL = 10;          // 全体インターバル秒数(ms)
input int interval_OPEN = 10;         // オーダーオープンインターバル秒数(ms)
input int interval_CLOSE = 10;        // 決済インターバル秒数(ms)
input int interval_RES = 10;          // 待機注文キャンセルインターバル秒数(ms)

long chart_id = ChartID(); // チャートID設定
double totalProfit = 0;

//--------------------------------------------------------------------------------------------//
int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
int slippage;
int total_BUY , total_SELL ,total_BUYSTOP,total_SELLSTOP;
datetime lastTime;
bool authed = false;
double AllProfit = 0;
double most_son = pipsstart*10 + pipsToMove*20;
double lots;
double profitTarget;


int OnInit() {
    while(OrdersTotal()>0){
    OrdersCloseAll();
    OrdersResAll();
    }
    Comment("");
    return (INIT_SUCCEEDED);
}

// +------------------------------------------------------------------+
// | |
// +------------------------------------------------------------------+
void OnDeinit(const int reason) {
 while(OrdersTotal()>0){
    OrdersCloseAll();
    OrdersResAll();
    }
    Comment("");
}

// +------------------------------------------------------------------+
// | ChartEvent function |
// +------------------------------------------------------------------+
void OnTick() {
   if(OrdersTotal()==0){
                profitTarget = AccountBalance() * bairitu / most_son * profitTargetpips;
                OrderOpen();
                Sleep(10);
    }else{
                    profitTarget = AccountBalance() * bairitu / most_son * profitTargetpips;
                    int i = 0;
                    int j=0;

                    while (j<1) {
                    Comment("損益: ",totalProfit," トータル益: ",AllProfit," 有効証拠金: ",AccountEquity()," 口座残高: ",AccountBalance()," 利確: ", profitTarget ," totalBUY: ", total_BUY ,"totalSELL: ", total_SELL );
                    if (IsStopped() == true) {
                        break;
                    }
                    totalProfit = AccountEquity()- AccountBalance();

                    // 利益が目標損益以上に達したら全ポジションを決済
                    if (totalProfit >= profitTarget) {
                    Print("保有ポジションの損益: ", totalProfit);
                    while(OrdersTotal()>0){
                        OrdersCloseAll();
                        OrdersResAll();
                        }
                        AllProfit += totalProfit;
                        j = 1;
                    }
                Sleep(interval_ALL);
            }
      }
}

void OrderOpen() {
    RefreshRates();
    lots = AccountBalance() * bairitu / most_son * 100 / MarketInfo(Symbol(),MODE_LOTSIZE);
    int ticket;
    double buyPrice = Ask + pipsstart * 10 * Point;
    double sellPrice = Bid - pipsstart * 10 * Point;
    slippage = int(slippagePips * Pips() / Point);
    Print("売り ", Bid , " 買い ", Ask,"　lots " , lots ,"　スリッページ ",slippage);
    Print("kai ",buyPrice," uri ",sellPrice);
    int i = 0;

    ticket = OrderSend(_Symbol, OP_BUYSTOP, lots, buyPrice, slippage, 0, 0, "", 0, clrNONE);
    ticket = OrderSend(_Symbol, OP_SELLSTOP, lots, sellPrice, slippage, 0, 0, "", 0, clrNONE);

    for (i = 1; i < 5; i++) {
        buyPrice = buyPrice + pipsToMove * 10 * Point;
        sellPrice = sellPrice - pipsToMove * 10 * Point;

        ticket = OrderSend(_Symbol, OP_BUYSTOP, lots, buyPrice, slippage, 0, 0, "", 0, clrNONE);
        if (ticket == -1) {
            Print("stopbuy ", i);
            break;
        }
        Sleep(interval_OPEN);

        ticket = OrderSend(_Symbol, OP_SELLSTOP, lots, sellPrice, slippage, 0, 0, "", 0, clrNONE);
        if (ticket == -1) {
            Print("stopsell ", i);
            break;
        }
        Sleep(interval_OPEN);
    }
}

// +------------------------------------------------------------------+
// | オーダーを全キャンセル ALL0rderCancel |
// | code by KOUSHIROU |
// | https://note.com/mt4_coder |
// +------------------------------------------------------------------+
void OrdersCloseAll() {
    slippage = int(slippagePips * Pips() / Point);
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
            bool Closed = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage, clrNONE);
            if (!Closed) {
                Print(GetLastError());
            }
            Sleep(interval_CLOSE);
        }
    }
}

void OrdersResAll() {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
            bool res = OrderDelete(OrderTicket(), clrNONE);
            if (!res) {
                Print(GetLastError());
            }
            Sleep(interval_RES);
        }
    }
}

// +------------------------------------------------------------------+
double Pips() {
    if (StringFind(Symbol(), "XAUUSD", 0) != -1 || StringFind(Symbol(), "GOLD", -1) != -1) {
        return NormalizeDouble(Point * 10, digits - 1);
    }

    if (digits == 3 || digits == 5) {
        return NormalizeDouble(Point * 10, digits - 1);
    }

    if (digits == 4 || digits == 2) {
        return Point;
    }
    return 0;
}
// +------------------------------------------------------------------+
