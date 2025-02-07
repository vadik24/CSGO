/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod (C)2013 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the SourceMod/SourcePawn SDK.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
 
#if defined _protobuf_included
#endinput
#endif
#define _protobuf_included

/**
 * Reads an int32, uint32, sint32, fixed32, or sfixed32 from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				Integer value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadInt(Handle:pb, const String:field[]);

/**
 * Reads a float or downcasted double from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				Float value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native Float:PbReadFloat(Handle:pb, const String:field[]);

/**
 * Reads a bool from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				Boolean value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native bool:PbReadBool(Handle:pb, const String:field[]);

/**
 * Reads a string from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param buffer		Destination string buffer.
 * @param maxlength		Maximum length of output string buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadString(Handle:pb, const String:field[], String:buffer[], maxlength);

/**
 * Reads an RGBA color value from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param buffer		Destination color buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadColor(Handle:pb, const String:field[], buffer[4]);

/**
 * Reads an XYZ angle value from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param buffer		Destination angle buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadAngle(Handle:pb, const String:field[], Float:buffer[3]);

/**
 * Reads an XYZ vector value from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param buffer		Destination vector buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadVector(Handle:pb, const String:field[], Float:buffer[3]);

/**
 * Reads an XY vector value from a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param buffer		Destination vector buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadVector2D(Handle:pb, const String:field[], Float:buffer[2]);

/**
 * Gets the number of elements in a repeated field of a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				Number of elements in the field.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbGetRepeatedFieldCount(Handle:pb, const String:field[]);

/**
 * Reads an int32, uint32, sint32, fixed32, or sfixed32 from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @return				Integer value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedInt(Handle:pb, const String:field[], index);

/**
 * Reads a float or downcasted double from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @return				Float value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native Float:PbReadRepeatedFloat(Handle:pb, const String:field[], index);

/**
 * Reads a bool from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @return				Boolean value read.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native bool:PbReadRepeatedBool(Handle:pb, const String:field[], index);

/**
 * Reads a string from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @param buffer		Destination string buffer.
 * @param maxlength		Maximum length of output string buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedString(Handle:pb, const String:field[], index, String:buffer[], size);

/**
 * Reads an RGBA color value from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @param buffer		Destination color buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedColor(Handle:pb, const String:field[], index, buffer[4]);

/**
 * Reads an XYZ angle value from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @param buffer		Destination angle buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedAngle(Handle:pb, const String:field[], index, Float:buffer[3]);

/**
 * Reads an XYZ vector value from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @param buffer		Destination vector buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedVector(Handle:pb, const String:field[], index, Float:buffer[3]);

/**
 * Reads an XY vector value from a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @param buffer		Destination vector buffer.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbReadRepeatedVector2D(Handle:pb, const String:field[], index, Float:buffer[2]);

/**
 * Sets an int32, uint32, sint32, fixed32, or sfixed32  on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Integer value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetInt(Handle:pb, const String:field[], value);

/**
 * Sets a float or double on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Float value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetFloat(Handle:pb, const String:field[], Float:value);

/**
 * Sets a bool on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Boolean value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetBool(Handle:pb, const String:field[], bool:value);

/**
 * Sets a string on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			String value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetString(Handle:pb, const String:field[], const String:value[]);

/**
 * Sets an RGBA color on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Color value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetColor(Handle:pb, const String:field[], const color[4]);

/**
 * Sets an XYZ angle on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Angle value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetAngle(Handle:pb, const String:field[], const Float:angle[3]);

/**
 * Sets an XYZ vector on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Vector value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetVector(Handle:pb, const String:field[], const Float:vec[3]);

/**
 * Sets an XY vector on a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Vector value to set.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbSetVector2D(Handle:pb, const String:field[], const Float:vec[2]);

/**
 * Add an int32, uint32, sint32, fixed32, or sfixed32 to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Integer value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddInt(Handle:pb, const String:field[], value);

/**
 * Add a float or double to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Float value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddFloat(Handle:pb, const String:field[], Float:value);

/**
 * Add a bool to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Boolean value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddBool(Handle:pb, const String:field[], bool:value);

/**
 * Add a string to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			String value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddString(Handle:pb, const String:field[], const String:value[]);

/**
 * Add an RGBA color to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Color value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddColor(Handle:pb, const String:field[], const color[4]);

/**
 * Add an XYZ angle to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Angle value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddAngle(Handle:pb, const String:field[], const Float:angle[3]);

/**
 * Add an XYZ vector to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Vector value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddVector(Handle:pb, const String:field[], const Float:vec[3]);

/**
 * Add an XY vector to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param value			Vector value to add.
 * @noreturn
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */
native PbAddVector2D(Handle:pb, const String:field[], const Float:vec[2]);

/**
 * Retrieve a handle to an embedded protobuf message in a protobuf message.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				protobuf handle to embedded message.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */ 
native Handle:PbReadMessage(Handle:pb, const String:field[]);

/**
 * Retrieve a handle to an embedded protobuf message in a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @param index			Index in the repeated field.
 * @return				protobuf handle to embedded message.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */ 
native Handle:PbReadRepeatedMessage(Handle:pb, const String:field[], index);

/**
 * Adds an embedded protobuf message to a protobuf message repeated field.
 *
 * @param pb			protobuf handle.
 * @param field			Field name.
 * @return				protobuf handle to added, embedded message.
 * @error				Invalid or incorrect Handle, non-existant field, or incorrect field type.
 */ 
native Handle:PbAddMessage(Handle:pb, const String:field[]);
