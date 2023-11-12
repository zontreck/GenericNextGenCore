#include "src/includes/common.lsl"

string PLUGIN_NAME = "Gag";

// Link Commands
integer     LINK_MENU_DISPLAY = 300;
integer     LINK_MENU_CLOSE = 310; 
integer     LINK_MENU_RETURN = 320;
integer     LINK_MENU_TIMEOUT = 330;
integer     LINK_MENU_CHANNEL = 303; // Returns from the dialog module to inform what the channel is
integer     LINK_MENU_ONLYCHANNEL = 302; // Sent with a ident to make a channel. No dialog will pop up, and it will expire just like any other menu if input is not received. 


string BACK = "<<";
string FORWARD = ">>";
list MENU_NAVIGATE_BUTTONS = [" ", " ", "-exit-"];

Menu(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

MenuNoUtility(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "NOUTIL", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetArbitraryData(key kAv, string sText, string sIdent, string sExtra){
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "FALSE", sText, "", "", sExtra, "", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetListenerChannel(string sIdent)
{
    llMessageLinked(LINK_THIS, LINK_MENU_ONLYCHANNEL, sIdent, sIdent);
}

NumberPad(key kAv, string sText, string sIdent, string sExtra)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, "numpadplz", "", sExtra, "NOUTIL", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}



call_menu(integer id, key kAv)
{

    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "check_mode", "callback", llList2Json(JSON_OBJECT, ["script", llGetScriptName(), "id", id])]), kAv);
}
integer g_iGagged;
integer g_iGagLevel;

integer g_iGagPrim;

Main(key kID, integer iAuth)
{
    list lMenu = ["main..", Checkbox(g_iGagged, "Gag")];
    list lHelper = [];
    string sText =  "Gag Menu";


    Menu(kID, sText, lMenu, "menu~gag", SetDSMeta([iAuth]), lHelper);
}
default
{
    state_entry()
    {
        integer i = 0;
        integer end = llGetNumberOfPrims();

        integer iHasGag = 0;
        for(i=LINK_ROOT; i<=end;i++)
        {
            string sDesc = llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]),0);
            if(sDesc == "gag")
            {
                g_iGagPrim = i;
                iHasGag=1;
            }
        }

        if(!iHasGag)
        {
            llOwnerSay(llGetScriptName()+" has been removed because the required prim could not be found. Please ensure a prim with the description of 'gag' is present.");
        }
    }

    link_message(integer s,integer n,string m,key i)
    {
        if(n==0)
        {
            if(llJsonGetValue(m,["cmd"]) == "reset")
            {
                llResetScript();
            } else if(llJsonGetValue(m,["cmd"]) == "scan_plugins")
            {
                llMessageLinked(LINK_SET,0,llList2Json(JSON_OBJECT, ["cmd", "plugin_reply", "name", PLUGIN_NAME]), "");
            } else if(llJsonGetValue(m,["cmd"]) == "pass_menu")
            {
                if(llJsonGetValue(m,["plugin"]) == PLUGIN_NAME)
                    call_menu(1, i);
            } else if(llJsonGetValue(m,["cmd"]) == "check_mode_back")
            {
                
                integer access = (integer)llJsonGetValue(m,["val"]);
                
                if(access != 99){
                    string sPacket = llJsonGetValue(m,["callback"]);
                    if(llGetScriptName() == llJsonGetValue(sPacket, ["script"]))
                    {
                        integer iMenu = (integer)llJsonGetValue(sPacket, ["id"]);
                                                
                        if(iMenu == 1)
                            Main(i, access);
                    }
                }
                else llRegionSayTo(i,0,"Access Denied");
                
            }  else if(llJsonGetValue(m,["cmd"]) == "read_setting_back")
            {
                string sSetting = llJsonGetValue(m,["setting"]);
                string sValue = llJsonGetValue(m,["value"]);

                switch(sSetting)
                {
                    case "gag_gagged":
                    {
                        g_iGagged = (integer)sValue;
                        break;
                    }
                    case "gag_level":
                    {
                        g_iGagLevel = (integer)sValue;
                        break;
                    }
                }
            }
        }else if(n == LINK_MENU_CHANNEL)
        {
            if(i == "ident")
            {
                //channel = m
            }
        }else if(n == LINK_MENU_RETURN)
        {
            if(llJsonGetValue(m, ["type"]) == "menu_back")
            {
                string sIdent = llJsonGetValue(m,["id"]);
                key kAv = i;
                string sReply = llJsonGetValue(m,["reply"]);
                string sExtra = llJsonGetValue(m,["extra"]);
                list lExtra = llParseString2List(sExtra, [":"],[]);

                integer iAuth = (integer)llList2String(lExtra,0);


                integer iRespring=1;
                integer iMenu;

                if(sReply == "-exit-")
                {
                    return;
                }
                switch(sIdent)
                {
                    case "menu~gag":
                    {
                        iMenu = 1;
                        switch(sReply)
                        {
                            case "main..":
                            {
                                iRespring=0;
                                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "pass_menu", "plugin", "Main"]), kAv);
                                break;
                            }
                        }
                        break;
                    }
                }

                if(iRespring)
                {
                    call_menu(iMenu, kAv);
                }
            }
        } else if(n == LM_SETTINGS_READY)
        {
            // Load Settings Here
            readSetting("gag_gagged", "0");
            readSetting("gag_level", "0");
        }
    }
}