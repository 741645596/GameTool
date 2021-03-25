using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace OmegaEditor.Extension
{
    public class VertexAttributeMask : IEnumerable<VertexAttribute>
    {
        public static VertexAttributeMask Base
        {
            get
            {
                return new VertexAttributeMask(
                    VertexAttribute.Position,
                    VertexAttribute.Normal,
                    VertexAttribute.TexCoord0);
            }
        }

        public static VertexAttributeMask Tan
        {
            get
            {
                return new VertexAttributeMask(
                    VertexAttribute.Position,
                    VertexAttribute.Normal,
                    VertexAttribute.Tangent,
                    VertexAttribute.TexCoord0);
            }
        }

        public static VertexAttributeMask Full
        {
            get
            {
                return new VertexAttributeMask(
                    VertexAttribute.Position,
                    VertexAttribute.Normal,
                    VertexAttribute.Tangent,
                    VertexAttribute.Color,
                    VertexAttribute.TexCoord0,
                    VertexAttribute.TexCoord1,
                    VertexAttribute.TexCoord2,
                    VertexAttribute.TexCoord3);
            }
        }

        protected const ushort VALIDATOR = 16383;

        protected ushort m_mask = 0;
        public ushort mask
        {
            get { return m_mask; }
            set { m_mask = (ushort)(VALIDATOR & value); }
        }

        public bool this[VertexAttribute attribute]
        {
            get { return (m_mask & (1 << (ushort)attribute)) > 0; }
            set { m_mask |= (ushort)(1 << (ushort)attribute); }
        }

        public VertexAttributeMask() { m_mask = 0; }

        public VertexAttributeMask(VertexAttribute attribute) : this()
        {
            this[attribute] = true;
        }

        public VertexAttributeMask(params VertexAttribute[] attributes) : this()
        {
            foreach (var attr in attributes)
                this[attr] = true;
        }

        public VertexAttributeMask(VertexAttributeMask attrMask)
        {
            m_mask = attrMask.m_mask;
        }

        public static implicit operator VertexAttributeMask(VertexAttribute attribute)
        {
            return new VertexAttributeMask(attribute);
        }

        public static implicit operator VertexAttributeMask(VertexAttribute[] attributes)
        {
            return new VertexAttributeMask(attributes);
        }

        public static implicit operator VertexAttributeMask(ushort mask)
        {
            return new VertexAttributeMask() { m_mask = mask };
        }

        public static implicit operator ushort(VertexAttributeMask attrMask)
        {
            return attrMask.m_mask;
        }

        public IEnumerator<VertexAttribute> GetEnumerator()
        {
            foreach (VertexAttribute attr in Enum.GetValues(typeof(VertexAttribute)))
            {
                if (this[attr])
                    yield return attr;
            }
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
    }
}
