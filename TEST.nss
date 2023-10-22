#include "NW_I0_GENERIC"
#include "our_constants"

string T3_GetTargetAltar(string condition)
{
    string c_AL = WpClosestAltarLeft();
    string c_AR = WpClosestAltarRight();
    string f_AL = WpFurthestAltarLeft();
    string f_AR = WpFurthestAltarRight();

    if (ClaimerOf(c_AL) == condition)
        return c_AL;
    else if (ClaimerOf(c_AR) == condition)
        return c_AR;
    else if (ClaimerOf(f_AL) == condition)
        return f_AL;
    else if (ClaimerOf(f_AR) == condition)
        return f_AR;
    else return "";
}

string T3_ChooseStrategicAltar(object self)
{
    string sMyColor = MyColor(self);
    string sOpponentColor = OpponentColor(self);

    string emptyAltar = T3_GetTargetAltar("");
    if (emptyAltar != "")
        return emptyAltar;
    

    string defAltar = T3_GetTargetAltar(sMyColor);
    string attackAltar = T3_GetTargetAltar(sOpponentColor);
    string targetAltar = "";
    string mode = "";

    if (defAltar != "")
    {
        targetAltar = defAltar;
        mode = "defend";
    }
    else if (attackAltar != "")
    {
        targetAltar = attackAltar;
        mode = "attack";
    }
    else
        return GetRandomTarget();

    object oAltar = GetObjectByTag(targetAltar);
    object oEnemy = GetNearestCreature(1, 1, oAltar, 1, -1, 2, 1);

    if (mode == "defend")
    {
        // Assuming 5.0 is a reasonable distance to detect threats
        if (GetIsObjectValid(oEnemy) && GetDistanceBetween(oAltar, oEnemy) <= 5.0)
            return targetAltar;
        
    }
    else if (mode == "attack")
    {
        // Assuming 5.0 is a reasonable distance to detect defenders
        if (!GetIsObjectValid(oEnemy) || GetDistanceBetween(oAltar, oEnemy) > 5.0)
            return targetAltar;
    }   

    return GetRandomTarget();

}

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T3_DetermineCombatRound( object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10 )
{
    DetermineCombatRound( oIntruder, nAI_Difficulty );
}

// Called every heartbeat (i.e., every six seconds).
void T3_HeartBeat()
{

    if (IsMaster())
    {
        int iHBcount = GetLocalInt( OBJECT_SELF, "HBCOUNT");
        iHBcount++;
        SetLocalInt( OBJECT_SELF, "HBCOUNT", iHBcount);
        SpeakString( "HB count: " + IntToString( iHBcount), TALKVOLUME_SHOUT );
    }

    // SpeakString( "hello", TALKVOLUME_SHOUT );

    if (GetIsInCombat())
        return;

    string sTarget = GetLocalString( OBJECT_SELF, "TARGET" );
    if (sTarget == "")
        {
        SpeakString( "st1", TALKVOLUME_SHOUT );
        return;
        }

    object oTarget = GetObjectByTag( sTarget );
    if (!GetIsObjectValid( oTarget ))
        {
        SpeakString( "sT3", TALKVOLUME_SHOUT );
        return;
        }

    // If there is a member of my own team close to the target and closer than me,
    // and no enemy is closer and this other member is not in combat and
    // has the same target, then choose a new target.
    float fToTarget = GetDistanceToObject( oTarget );
    int i = 1;
    int bNewTarget = FALSE;
    object oCreature = GetNearestObjectToLocation( OBJECT_TYPE_CREATURE, GetLocation( oTarget ), i );
    while (GetIsObjectValid( oCreature ))
    {
        if (GetLocation( oCreature ) == GetLocation( OBJECT_SELF ))
            break;
        if (GetDistanceBetween( oCreature, oTarget ) > fToTarget)
            break;
        if (GetDistanceBetween( oCreature, oTarget ) > 5.0)
            break;
        if (!SameTeam( oCreature ))
            break;
        if (GetIsInCombat( oCreature ))
            break;
        if (GetLocalString( oCreature, "TARGET" ) == sTarget)
        {
            bNewTarget = TRUE;
            break;
        }
        ++i;
        oCreature = GetNearestObjectToLocation( OBJECT_TYPE_CREATURE, GetLocation( oTarget ), i );
    }

    if (bNewTarget)
    {
        sTarget = T3_ChooseStrategicAltar( OBJECT_SELF );
        SetLocalString( OBJECT_SELF, "TARGET", sTarget );
        oTarget = GetObjectByTag( sTarget );
        if (!GetIsObjectValid( oTarget ))
            {
            SpeakString( "st3", TALKVOLUME_SHOUT );
            return;
            }
        fToTarget = GetDistanceToObject( oTarget );
    }

    if (fToTarget > 0.5)
        ActionMoveToLocation( GetLocation( oTarget ), TRUE );

    return;
}

// Called when the NPC is spawned.
void T3_Spawn()
{
    string sTarget = T3_ChooseStrategicAltar( OBJECT_SELF );
    SetLocalString( OBJECT_SELF, "TARGET", sTarget );
    ActionMoveToLocation( GetLocation( GetObjectByTag( sTarget ) ), TRUE );
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T3_UserDefined( int Event )
{
    switch (Event)
    {
        // The NPC has just been attacked.
        case EVENT_ATTACKED:
            break;

        // The NPC was damaged.
        case EVENT_DAMAGED:
            break;

        // At the end of one round of combat.
        case EVENT_END_COMBAT_ROUND:
            break;

        // Every heartbeat (i.e., every six seconds).
        case EVENT_HEARTBEAT:
            T3_HeartBeat();
            break;

        // Whenever the NPC perceives a new creature.
        case EVENT_PERCEIVE:
            break;

        // When a spell is cast at the NPC.
        case EVENT_SPELL_CAST_AT:
            break;

        // Whenever the NPC's inventory is disturbed.
        case EVENT_DISTURBED:
            break;

        // Whenever the NPC dies.
        case EVENT_DEATH:
            break;

        // When the NPC has just been spawned.
        case EVENT_SPAWN:
            T3_Spawn();
            break;
    }

    return;
}

// Called when the fight starts, just before the initial spawning.
void T3_Initialize( string sColor )
{
    SetTeamName( sColor, "Default-" + GetStringLowerCase( sColor ) );
}