using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;
using System.Threading;

namespace UnityPhysXExport
{
	public static class PhysXIDBuilder
	{
		public enum ObjType : byte
		{
			None = 0,       //0000
			Unknown = 1,    //0001
			Ground = 2,     //0010
			Water = 3,      //0011
			Building = 4,   //0100
			Rock = 5,       //0101
			Tree = 6,       //0110
			Adorning = 7,   //0111
            Sea = 8
			//Player  = 15    //1111
		}

		static long m_autoIncID = 0;
		static long autoIncID
		{
			get
			{
				return Interlocked.Increment(ref m_autoIncID);
			}
		}

		public static void Init()
		{
			m_autoIncID = 0;
		}

		public static long GenerateID(ObjType type)    //XXXX 0000 0000 0000
		{                                              //0000 0000 0000 0000
			long ID = (long)type << 60;                //YYYY YYYY YYYY YYYY
			ID |= autoIncID;                           //YYYY YYYY YYYY YYYY
			return ID;                                 //XXXX(高4位) : type
		}                                              //YYYY(低32位): unique ID
	}
}