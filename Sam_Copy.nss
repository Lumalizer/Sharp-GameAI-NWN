#include "NW_I0_GENERIC"
#include "our_constants"
#include "our_functions"

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T3_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DoHealing();
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

// Called every heartbeat (i.e., every six seconds).
void T3_HeartBeat() {
	// ShoutClosestEnemyLocation(OBJECT_SELF);

	if (GetIsInCombat()) return;
	DoHealing();

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;
	SetNewTargetIfNeeded(sTarget, OBJECT_SELF, "smart");
	sTarget = GetLocalString(OBJECT_SELF, "TARGET");

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	float fToTarget = GetDistanceToObject(oTarget);
	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

// Called when the NPC is spawned.
void T3_Spawn() {
	string sTarget = ChooseStrategicAltar(OBJECT_SELF);
	string sMessage = "Going to: " + sTarget;
	SpeakString(sMessage, TALKVOLUME_SHOUT);
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T3_UserDefined(int Event) {
	switch (Event) {
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
void T3_Initialize(string sColor) { SetTeamName(sColor, "Team-" + GetStringLowerCase(sColor)); }
