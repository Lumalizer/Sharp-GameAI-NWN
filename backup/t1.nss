#include "NW_I0_GENERIC"
#include "our_constants"

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T1_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

// Called every heartbeat (i.e., every six seconds).
void T1_HeartBeat() {
	if (GetIsInCombat()) return;

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	// If there is a member of my own team close to the target and closer than me,
	// and no enemy is closer and this other member is not in combat and
	// has the same target, then choose a new target.
	float fToTarget = GetDistanceToObject(oTarget);
	int i = 1;
	int bNewTarget = FALSE;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	while (GetIsObjectValid(oCreature)) {
		if (GetLocation(oCreature) == GetLocation(OBJECT_SELF)) break;
		if (GetDistanceBetween(oCreature, oTarget) > fToTarget) break;
		if (GetDistanceBetween(oCreature, oTarget) > 5.0) break;
		if (!SameTeam(oCreature)) break;
		if (GetIsInCombat(oCreature)) break;
		if (GetLocalString(oCreature, "TARGET") == sTarget) {
			bNewTarget = TRUE;
			break;
		}
		++i;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	}

	if (bNewTarget) {
		sTarget = GetRandomTarget();
		SetLocalString(OBJECT_SELF, "TARGET", sTarget);
		oTarget = GetObjectByTag(sTarget);
		if (!GetIsObjectValid(oTarget)) return;
		fToTarget = GetDistanceToObject(oTarget);
	}

	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

// Called when the NPC is spawned.
void T1_Spawn() {
	string sTarget = GetRandomTarget();
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T1_UserDefined(int Event) {
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
			T1_HeartBeat();
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
			T1_Spawn();
			break;
	}

	return;
}

// Called when the fight starts, just before the initial spawning.
void T1_Initialize(string sColor) { SetTeamName(sColor, "Default-" + GetStringLowerCase(sColor)); }