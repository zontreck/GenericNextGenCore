#include "src/includes/common.lsl"



/*

    DISCLAIMER

    Some code has been sourced from the OpenCollar project, some is my own personal code that may look similar to OpenCollar, because i was the one who contributed it in the first place.



*/



string LEASH_HOLDER = "[DHB]Leather Handle";
string LEASH_WALL_RING = "[DHB]Wall Ring";
string LEASH_POST = "[DHB]Leash Post";

string PLUGIN_NAME = "Leash";

// Link Commands
integer     LINK_MENU_DISPLAY = 300;
integer     LINK_MENU_CLOSE = 310; 
integer     LINK_MENU_RETURN = 320;
integer     LINK_MENU_TIMEOUT = 330;
integer     LINK_MENU_CHANNEL = 303; // Returns from the dialog module to inform what the channel is
integer     LINK_MENU_ONLYCHANNEL = 302; // Sent with a ident to make a channel. No dialog will pop up, and it will expire just like any other menu if input is not received. 

string g_sParticleTextureID="4cde01ac-4279-2742-71e1-47ff81cc3529";


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

Main(key kID, integer iAuth)
{
    list lMenu = ["main..", "Length", Checkbox(g_iTurn, "Turn2Leasher"), "Tools..", "Color"];
    if(g_kLeashedTo)
    {
        // Unleash button
        // Post button

        // Check Authority Level
        if(iAuth <= g_iLeashedToAuth)
        {
            lMenu += ["Unleash", "Post"];
        }
    }else {
        // Grab Leash
        // Post

        if(kID != llGetOwner()) lMenu += ["Grab Leash"];
        lMenu += ["Post"];
    }

    list lHelper = [];
    string sText =  "Leash Menu";


    Menu(kID, sText, lMenu, "menu~Leash", SetDSMeta([iAuth]), lHelper);
}

list g_lLeashPoints = [];
LPSearch()
{
    g_lLeashPoints = [];
    integer ix=0;
    integer end = llGetNumberOfPrims();

    for(ix=LINK_ROOT; ix<=end;ix++)
    {
        list lPar = llGetLinkPrimitiveParams(ix, [PRIM_DESC]);
        if(llList2String(lPar,0) == "leash point")
        {
            g_lLeashPoints += [ix];
        }
    }
}

integer g_iTurn;
key g_kLeashedTo;
integer g_iLeashedToAuth;
integer g_iLeashLength;

ToolsMenu(key kID, integer iAuth)
{
    list lMenu = ["back..", "Leash Holder", "Leash Post", "Wall Ring"];
    list lHelper = ["Go back to the leash menu", "Receive a leash holder", "Receive a rezzable leash post", "Receive a wall ring that can be rezzed"];

    Menu(kID, "Leash Tools\n\n", lMenu, "menu~LeashTools", SetDSMeta([iAuth]), lHelper);
}

PostScan(key kAv, integer iAuth)
{
    UpdateDSRequest(NULL, "postscan", SetDSMeta([kAv, iAuth]));

    llSensor("", "", SCRIPTED, 20, PI);
}

PostMenu(key kID, integer iAuth, list lOptions)
{
    list lMenu = ["back.."] + lOptions;
    string sMenu = "What object do you want to attach the leash to?\n\n";

    Menu(kID, sMenu, lMenu, "leash~post", SetDSMeta([iAuth]), []);
}

vector g_vLeashColor = <1.00000, 1.00000, 1.00000>;
vector g_vLeashSize = <0.04, 0.04, 1.0>;
integer g_iParticleGlow = TRUE;
float g_fParticleAge = 3.5;
vector g_vLeashGravity = <0.0,0.0,-1.0>;
integer g_iParticleCount = 1;
float g_fBurstRate = 0.0;

list CalculateParticles(key kParticleTarget)
{
    integer iFlags = PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK;

    list lTemp = [
        PSYS_PART_MAX_AGE,g_fParticleAge,
        PSYS_PART_FLAGS,iFlags,
        PSYS_PART_START_COLOR, g_vLeashColor,
        //PSYS_PART_END_COLOR, g_vLeashColor,
        PSYS_PART_START_SCALE,g_vLeashSize,
        //PSYS_PART_END_SCALE,g_vLeashSize,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_SRC_BURST_RATE,g_fBurstRate,
        PSYS_SRC_ACCEL, g_vLeashGravity,
        PSYS_SRC_BURST_PART_COUNT,g_iParticleCount,
        //PSYS_SRC_BURST_SPEED_MIN,fMinSpeed,
        //PSYS_SRC_BURST_SPEED_MAX,fMaxSpeed,
        PSYS_SRC_TARGET_KEY,kParticleTarget,
        PSYS_SRC_MAX_AGE, 0,
        PSYS_SRC_TEXTURE, g_sParticleTextureID
        ];
    return lTemp;
}

StopParticles()
{
    integer i=0;
    integer end = llGetListLength(g_lLeashPoints);
    for(i=0;i<end;i++)
    {
        llLinkParticleSystem(llList2Integer(g_lLeashPoints,i),[]);
    }
}

RefreshParticles()
{
    if(g_kLeashedTo)
    {
        integer i=0;
        integer end = llGetListLength(g_lLeashPoints);
        for(i=0;i<end;i++)
        {
            llLinkParticleSystem(llList2Integer(g_lLeashPoints,i), CalculateParticles(g_kLeashedTo));
        }
    }else {
        StopParticles();
    }
}

UpdateRLV()
{
    if(g_kLeashedTo)
    {
        llOwnerSay("@fly=n,tplm=n,tplure=n,tploc=n,tplure:"+(string)g_kLeashedTo+"=add,fartouch=n,sittp=n");
    }else {
        llOwnerSay("@fly=y,tplm=y,tplure=y,tploc=y,clear=tplure,fartouch=y,sittp=y");
    }
}

integer g_iTargetHandle;
vector g_vTargetPos;
integer g_iJustMoved = FALSE;
integer g_iTargetInRange;
integer g_iAwayCounter;

CheckLeashMovement()
{
    if(g_kLeashedTo)
    {

        g_vTargetPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]),0);
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();

        g_iTargetHandle = llTarget(g_vTargetPos, (float)g_iLeashLength);

        llSetTimerEvent(3);
    }else {
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();
        llSetTimerEvent(0);
    }
}


default
{
    state_entry()
    {
        // Load settings here
        LPSearch();

    }

    timer()
    {
        vector vLeashedToPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]), 0);
        integer iIsInSimOrOutside = TRUE;
        if(vLeashedToPos == ZERO_VECTOR || llVecDist(llGetPos(), vLeashedToPos) > 255) iIsInSimOrOutside=FALSE;

        if(iIsInSimOrOutside && llVecDist(llGetPos(), vLeashedToPos) < (60 + g_iLeashLength))
        {
            if(!g_iTargetInRange)
            {
                g_iAwayCounter = -1;
                llSetTimerEvent(3);
            }

            g_iTargetInRange = TRUE;
            llTargetRemove(g_iTargetHandle);
            g_vTargetPos = vLeashedToPos;

            g_iTargetHandle = llTarget(g_vTargetPos, (float)g_iLeashLength);
        } else {
            if(g_iTargetInRange)
            {
                if(g_iAwayCounter <= llGetUnixTime())
                {
                    llTargetRemove(g_iTargetHandle);

                    llStopMoveToTarget();
                    g_iTargetInRange=FALSE;
                    UpdateRLV();
                    g_iAwayCounter=-1;

                } else if(g_iAwayCounter == -1)
                {
                    g_iAwayCounter = llGetUnixTime()+ (5*60);
                }
            }else {
                if(llGetUnixTime() > g_iAwayCounter)
                {
                    deleteSetting("leash_leashedto", "");

                    llRegionSayTo(llGetOwner(), 0, "SAFETY UNLEASH\n\n[ The leash holder has been gone for more than five minutes ]");
                }


            }
        }
    }

    at_target(integer iNum, vector vTarget, vector vMe)
    {
        llStopMoveToTarget();

        llTargetRemove(g_iTargetHandle);
        g_vTargetPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]),0);
        g_iTargetHandle = llTarget(g_vTargetPos, (float)g_iLeashLength);

        if(g_iJustMoved)
        {
            vector vPointTo = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]),0) - llGetPos();
            float fAngle = llAtan2(vPointTo.x, vPointTo.y);
            if(g_iTurn) llOwnerSay("@setrot:" + (string)fAngle + "=force");
            g_iJustMoved=FALSE;
        }

    }

    not_at_target(){
        g_iJustMoved=1;

        if(g_kLeashedTo)
        {
            vector vNewPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]),0);

            if(g_vTargetPos != vNewPos)
            {
                llTargetRemove(g_iTargetHandle);
                g_vTargetPos = vNewPos;
                g_iTargetHandle = llTarget(g_vTargetPos, (float)g_iLeashLength);
            }

            if(g_vTargetPos != ZERO_VECTOR)
            {
                llMoveToTarget(g_vTargetPos, 1.0);
            }else {
                llStopMoveToTarget();
                llTargetRemove(g_iTargetHandle);
            }
        } else {
            llStopMoveToTarget();
            llTargetRemove(g_iTargetHandle);
        }
    }

    sensor(integer iNum)
    {
        integer i=0;
        list lMeta = GetMetaList("postscan");
        DeleteDSReq("postscan");
        list lResults = [];

        for(i=0;i<iNum; i++)
        {
            lResults += [llDetectedKey(i)];
        }

        PostMenu(llList2String(lMeta,0), (integer)llList2String(lMeta,1), lResults);
    }

    no_sensor()
    {
        list lMeta = GetMetaList("postscan");
        DeleteDSReq("postscan");

        PostMenu((key)llList2String(lMeta,0), (integer)llList2String(lMeta,1), []);
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
                        else if(iMenu ==2)
                            NumberPad(i, "How long do you want the leash in meters?\nMax value: 50\nCurrent: "+(string)g_iLeashLength+"\n\n", "length", SetDSMeta([access]));
                        else if(iMenu ==3)
                            ToolsMenu(i, access);
                        else if(iMenu == 4)
                            PostScan(i, access);
                        else if(iMenu == 5)
                            Menu(i, "What color do you want to choose?\n\nCurrent Color: "+ (string)g_vLeashColor, ["colormenu"], "menu~LeashColor", SetDSMeta([access]), []);
                    }
                }
                else llRegionSayTo(i,0,"Access Denied");
                
            } else if(llJsonGetValue(m,["cmd"]) == "read_setting_back")
            {
                string sSetting = llJsonGetValue(m,["setting"]);
                string sValue = llJsonGetValue(m,["value"]);

                switch(sSetting)
                {
                    case "leash_turn":
                    {
                        g_iTurn = (integer)sValue;
                        break;
                    }
                    case "leash_leashedto":
                    {
                        if(sValue == "")
                        {
                            g_kLeashedTo = NULL_KEY;
                            g_iLeashedToAuth = 0;
                        }else {

                            g_kLeashedTo = llJsonGetValue(sValue, ["id"]);
                            g_iLeashedToAuth = (integer)llJsonGetValue(sValue, ["level"]);
                        }
                        break;
                    }
                    case "leash_length":
                    {
                        g_iLeashLength = (integer)sValue;
                        break;
                    }
                    case "leash_color":
                    {
                        g_vLeashColor = (vector)sValue;
                        break;
                    }
                }
                if(llSubStringIndex(sSetting, "leash")!=-1)
                {
                    RefreshParticles();
                    UpdateRLV();
                    
                    // Assert the Leash movement updates as well
                    CheckLeashMovement();
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
                    case "menu~Leash":
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
                            case "Length":
                            {
                                iMenu=2;
                                break;
                            }
                            case Checkbox(g_iTurn, "Turn2Leasher"):
                            {
                                g_iTurn=!g_iTurn;
                                writeSetting("leash_turn", (string)g_iTurn);
                                break;
                            }
                            case "Tools..":
                            {
                                iMenu=3;
                                break;
                            }
                            case "Post":
                            {
                                iMenu=4;
                                break;
                            }
                            case "Unleash":
                            {
                                if(iAuth <= g_iLeashedToAuth){

                                    deleteSetting("leash_leashedto", "");

                                    llRegionSayTo(llGetOwner(), 0, "You've been unleashed by " + SLURL(kAv));
                                }

                                break;
                            }
                            case "Grab Leash":
                            {
                                integer iLeash=1;
                                if(g_kLeashedTo)
                                {
                                    if(!(iAuth <= g_iLeashedToAuth))
                                    {
                                        llRegionSayTo(kAv, 0, "The leash is currently held by " + SLURL(g_kLeashedTo)+". You lack the authority to take it from them.");
                                        iLeash=0;
                                    }
                                }
                                
                                if(iLeash){
                                    writeSetting("leash_leashedto", llList2Json(JSON_OBJECT, ["id", kAv, "level", iAuth]));

                                    if(g_kLeashedTo)
                                        llRegionSayTo(g_kLeashedTo, 0, SLURL(kAv)+" takes the leash from you");

                                    llRegionSayTo(kAv,0,"You grab "+SLURL(llGetOwner()) +"'s leash");
                                    llRegionSayTo(llGetOwner(), 0, "Your leash was grabbed by " + SLURL(kAv));
                                }
                                
                            }
                            case "Color":
                            {
                                iMenu=5;
                                break;
                            }
                        }
                        break;
                    }
                    case "length":
                    {
                        iMenu = 1;
                        if(sReply != "-1"){

                            integer len = (integer)sReply;
                            if(len >= 50)
                            {
                                len = 50;
                            }

                            if(len <= 0) len = 1;

                            writeSetting("leash_length", (string)len);


                        }

                        break;
                    }
                    case "menu~LeashColor":
                    {
                        writeSetting("leash_color", sReply);
                        iMenu=1;
                        break;
                    }
                    case "menu~LeashTools":
                    {
                        iMenu=3;
                        switch(sReply)
                        {
                            case "back..":
                            {
                                iMenu=1;
                                break;
                            }
                            case "Leash Holder":
                            {
                                llGiveInventory(kAv, LEASH_HOLDER);
                                break;
                            }
                            case "Wall Ring":
                            {
                                llGiveInventory(kAv, LEASH_WALL_RING);
                                break;
                            }
                            case "Leash Post":
                            {
                                llGiveInventory(kAv, LEASH_POST);
                                break;
                            }
                        }
                        break;
                    }
                    case "leash~post":
                    {
                        iMenu=1;
                        switch(sReply)
                        {
                            case "back..":
                            {
                                iMenu=1;
                                break;
                            }
                            default:
                            {
                                // Leash to object
                                llRegionSayTo(kAv,0,"Leashing to "  + llKey2Name(sReply)+" ...");

                                writeSetting("leash_leashedto", llList2Json(JSON_OBJECT, ["id", sReply, "level", iAuth]));
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

            readSetting("leash_leashedto", "");
            readSetting("leash_length", "5");
            readSetting("leash_turn", "0");
            readSetting("leash_color", "<1,1,1>");
        }
    }
}