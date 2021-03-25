using System.IO;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.Reflection;
using System.Collections.Generic;

namespace OmegaEditor.Extension
{
    public enum DumpFormat
    {
        TGA = 0, // Require Unity 2018.3 or above
        PNG = 1,
        JPG = 2,
        EXR = 3
    }

    public enum TextureRes
    {
        //_8x8 = 8,
        //_16x16 = 16,
        _32x32 = 32,
        _64x64 = 64,
        _128x128 = 128,
        _256x256 = 256,
        _512x512 = 512,
        _1024x1024 = 1024,
        _2048x2048 = 2048,
        _4096x4096 = 4096,
        _8192x8192 = 8192
    }

    public enum ResizeFilterMode
    {
        Point = 0,
        Bilinear = 1
    }

    public enum TextureChannel
    {
        R    =  8, //1000
        //G   =  4, //0100
        //B   =  2, //0010
        A    =  1, //0001
        RG   = 12, //1100
        RGB  = 14, //1110
        RGBA = 15  //1111
    }

    public enum MobileTextureFormat
    {
        Automatic = -1,
        /*
        Alpha_8 = 1,
        RGB_24_bit = 3,
        RGBA_32_bit = 4,
        RGB_16_bit = 7,
        R_16_bit = 9,
        RGB_DXT1 = 10,
        RGBA_DXT5 = 12,
        RGBA_16_bit = 13,
        RGBA_Half = 17,
        RGB_Crunched_DXT1 = 28,
        RGBA_Crunched_DXT5 = 29,
        */
        PVRTC_RGB_2bits = 30,
        PVRTC_RGBA_2_bits = 31,
        PVRTC_RGB_4_bits = 32,
        PVRTC_RGBA_4_bits = 33,

        ETC_RGB_4_bits = 34,
        ETC_Crunched_RGB_4_bits = 64,

        EAC_R_4_bit = 41,
        EAC_RG_8_bit = 43,

        ETC2_RGB_4_bits = 45,
        ETC2_RGB_4_bits_1_Alpha = 46,
        ETC2_RGBA_8_bits = 47,
        ETC2_Crunched_RGBA_8_bits = 65,

        ASTC_RGB_4x4_block = 48,
        ASTC_RGB_5x5_block = 49,
        ASTC_RGB_6x6_block = 50,
        ASTC_RGB_8x8_block = 51,
        ASTC_RGB_10x10_block = 52,
        ASTC_RGB_12x12_block = 53,

        ASTC_RGBA_4x4_block = 54,
        ASTC_RGBA_5x5_block = 55,
        ASTC_RGBA_6x6_block = 56,
        ASTC_RGBA_8x8_block = 57,
        ASTC_RGBA_10x10_block = 58,
        ASTC_RGBA_12x12_block = 59,
        //R_8 = 63,
    }

    public static class TextureFormatExtension
    {
        static Dictionary<TextureFormat, float> compression;
        static Dictionary<TextureFormat, TextureChannel> channel;
        static Dictionary<TextureFormat, int> bit;

        public static float GetCompressionRate(this TextureFormat format)
        {
            if (compression.ContainsKey(format))
                return compression[format];
            else return 1f;
        }

        public static float GetCompressionRatio(this TextureFormat format)
        {
            return 1f / GetCompressionRate(format);
        }

        public static TextureChannel GetChannel(this TextureFormat format)
        {
            TextureChannel ch;
            if (channel.TryGetValue(format, out ch))
                return ch;
            else return TextureChannel.RGBA;
        }

        public static int GetBytes(this TextureChannel channelMode)
        {
            switch (channelMode)
            {
                case TextureChannel.A: { return 1; }
                case TextureChannel.R: { return 1; }
                case TextureChannel.RG: { return 2; }
                case TextureChannel.RGB: { return 3; }
                case TextureChannel.RGBA: { return 4; }
                default: { return 4; }
            }
        }

        public static float GetRuntimeMemorySizeKB(this Texture2D texture)
        {
            /*TextureChannel channel = texture.format.GetChannel();
            float compressionRate = texture.format.GetCompressionRate();
            float sizeByte = texture.width * texture.height * channel.GetBytes();
            float sizeKB = sizeByte * compressionRate / 1024f;
            TextureImporter importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(texture)) as TextureImporter;
            sizeKB *= importer.mipmapEnabled ? 4f / 3f : 1f;
            sizeKB *= texture.isReadable ? 2f : 1f;
            return sizeKB;*/
            //return UnityEngine.Profiling.Profiler.GetRuntimeMemorySizeLong(texture) / 1024f;
            float storageSize = texture.GetStorageMemorySizeKB();
            return texture.isReadable ? storageSize * 2f : storageSize;
        }

        public static float GetStorageMemorySizeKB(this Texture2D texture)
        {
            var TextureUtil = Assembly.Load("UnityEditor.dll")
                .GetType("UnityEditor.TextureUtil");
            MethodInfo methodInfo = TextureUtil.GetMethod("GetStorageMemorySizeLong",
                BindingFlags.Static | BindingFlags.Instance | BindingFlags.Public);
            return (long)methodInfo.Invoke(null, new object[] { texture }) / 1024f;
        }

        static TextureFormatExtension()
        {
            #region compressionRate
            compression = new Dictionary<TextureFormat,float>();
            compression.Add(TextureFormat.Alpha8, 1f);
            compression.Add(TextureFormat.ARGB4444, 2f/ 3f);
            compression.Add(TextureFormat.RGB24, 1f);
            compression.Add(TextureFormat.RGBA32, 1f);
            compression.Add(TextureFormat.ARGB32, 1f);
            compression.Add(TextureFormat.RGB565, 0.5f);
            compression.Add(TextureFormat.R16, 2f);
            compression.Add(TextureFormat.DXT1, 1f / 4f);
            compression.Add(TextureFormat.DXT5, 1f / 4f);
            compression.Add(TextureFormat.RGBA4444, 0.5f);
            compression.Add(TextureFormat.BGRA32, 1f);
            compression.Add(TextureFormat.RHalf, 2f);
            compression.Add(TextureFormat.RGHalf, 2f);
            compression.Add(TextureFormat.RGBAHalf, 2f);
            compression.Add(TextureFormat.RFloat, 4f);
            compression.Add(TextureFormat.RGFloat, 4f);
            compression.Add(TextureFormat.RGBAFloat, 4f);
            compression.Add(TextureFormat.YUY2, 0.5f);
            compression.Add(TextureFormat.RGB9e5Float, 4f / 3f);
            //compression.Add(TextureFormat.BC6H, 1f);
            //compression.Add(TextureFormat.BC7, 1f);
            //compression.Add(TextureFormat.BC4, 1f);
            //compression.Add(TextureFormat.BC5, 1f);
            //compression.Add(TextureFormat.DXT1Crunched, 1f);
            //compression.Add(TextureFormat.DXT5Crunched, 1f);

            compression.Add(TextureFormat.PVRTC_RGB2, 2f / 24f);
            compression.Add(TextureFormat.PVRTC_RGBA2, 2f / 32f);
            compression.Add(TextureFormat.PVRTC_RGB4, 4f / 24f);
            compression.Add(TextureFormat.PVRTC_RGBA4, 4f / 32f);

            compression.Add(TextureFormat.ETC_RGB4, 4f / 24f);

            compression.Add(TextureFormat.ETC2_RGB, 4f / 24f);
            compression.Add(TextureFormat.ETC2_RGBA1, 5f / 32f);
            compression.Add(TextureFormat.ETC2_RGBA8, 8f / 32f);

            compression.Add(TextureFormat.ASTC_4x4,   128f / (4f * 4f * 24f));
            compression.Add(TextureFormat.ASTC_5x5,   128f / (5f * 5f * 24f));
            compression.Add(TextureFormat.ASTC_6x6,   128f / (6f * 6f * 24f));
            compression.Add(TextureFormat.ASTC_8x8,   128f / (8f * 8f * 24f));
            compression.Add(TextureFormat.ASTC_10x10, 128f / (10f * 10f * 24f));
            compression.Add(TextureFormat.ASTC_12x12, 128f / (12f * 12f * 24f));

            compression.Add(TextureFormat.ASTC_4x4,   128f / (4f * 4f * 32f));
            compression.Add(TextureFormat.ASTC_5x5,   128f / (5f * 5f * 32f));
            compression.Add(TextureFormat.ASTC_6x6,   128f / (6f * 6f * 32f));
            compression.Add(TextureFormat.ASTC_8x8,   128f / (8f * 8f * 32f));
            compression.Add(TextureFormat.ASTC_10x10, 128f / (10f * 10f * 32f));
            compression.Add(TextureFormat.ASTC_12x12, 128f / (12f * 12f * 32f));

            compression.Add(TextureFormat.ETC_RGB4_3DS, 4f / 24f);
            compression.Add(TextureFormat.ETC_RGBA8_3DS, 8f / 32f);

            compression.Add(TextureFormat.RG16, 1f);
            compression.Add(TextureFormat.R8, 1f);

            compression.Add(TextureFormat.ETC_RGB4Crunched, 0.03125f);
            compression.Add(TextureFormat.ETC2_RGBA8Crunched, 0.0625f);
            #endregion

            #region channel
            channel = new Dictionary<TextureFormat, TextureChannel>();
            channel.Add(TextureFormat.Alpha8, TextureChannel.A);
            channel.Add(TextureFormat.ARGB4444, TextureChannel.RGBA);
            channel.Add(TextureFormat.RGB24, TextureChannel.RGB);
            channel.Add(TextureFormat.RGBA32, TextureChannel.RGBA);
            channel.Add(TextureFormat.ARGB32, TextureChannel.RGBA);
            channel.Add(TextureFormat.RGB565, TextureChannel.RGB);
            channel.Add(TextureFormat.R16, TextureChannel.R);
            channel.Add(TextureFormat.DXT1, TextureChannel.RGB);
            channel.Add(TextureFormat.DXT5, TextureChannel.RGBA);
            channel.Add(TextureFormat.RGBA4444, TextureChannel.RGBA);
            channel.Add(TextureFormat.BGRA32, TextureChannel.RGBA);
            channel.Add(TextureFormat.RHalf, TextureChannel.R);
            channel.Add(TextureFormat.RGHalf, TextureChannel.RG);
            channel.Add(TextureFormat.RGBAHalf, TextureChannel.RGBA);
            channel.Add(TextureFormat.RFloat, TextureChannel.R);
            channel.Add(TextureFormat.RGFloat, TextureChannel.RG);
            channel.Add(TextureFormat.RGBAFloat, TextureChannel.R);
            channel.Add(TextureFormat.YUY2, TextureChannel.RGB);
            channel.Add(TextureFormat.RGB9e5Float, TextureChannel.RGB);
            channel.Add(TextureFormat.BC6H, TextureChannel.RGB);
            channel.Add(TextureFormat.BC7, TextureChannel.RGBA);
            channel.Add(TextureFormat.BC4, TextureChannel.R);
            channel.Add(TextureFormat.BC5, TextureChannel.RG);
            channel.Add(TextureFormat.DXT1Crunched, TextureChannel.RGBA);
            channel.Add(TextureFormat.DXT5Crunched, TextureChannel.RGBA);
            channel.Add(TextureFormat.PVRTC_RGB2, TextureChannel.RGB);
            channel.Add(TextureFormat.PVRTC_RGBA2, TextureChannel.RGBA);
            channel.Add(TextureFormat.PVRTC_RGB4, TextureChannel.RGB);
            channel.Add(TextureFormat.PVRTC_RGBA4, TextureChannel.RGBA);
            channel.Add(TextureFormat.ETC_RGB4, TextureChannel.RGB);
            channel.Add(TextureFormat.EAC_R, TextureChannel.R);
            channel.Add(TextureFormat.EAC_R_SIGNED, TextureChannel.R);
            channel.Add(TextureFormat.EAC_RG, TextureChannel.RG);
            channel.Add(TextureFormat.EAC_RG_SIGNED, TextureChannel.RG);
            channel.Add(TextureFormat.ETC2_RGB, TextureChannel.RGB);
            channel.Add(TextureFormat.ETC2_RGBA1, TextureChannel.RGBA);
            channel.Add(TextureFormat.ETC2_RGBA8, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_4x4, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_5x5, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_6x6, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_8x8, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_10x10, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_12x12, TextureChannel.RGB);
            channel.Add(TextureFormat.ASTC_4x4, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_5x5, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_6x6, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_8x8, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_10x10, TextureChannel.RGBA);
            channel.Add(TextureFormat.ASTC_12x12, TextureChannel.RGBA);
            channel.Add(TextureFormat.ETC_RGB4_3DS, TextureChannel.RGB);
            channel.Add(TextureFormat.ETC_RGBA8_3DS, TextureChannel.RGBA);
            channel.Add(TextureFormat.RG16, TextureChannel.RG);
            channel.Add(TextureFormat.R8, TextureChannel.R);
            channel.Add(TextureFormat.ETC_RGB4Crunched, TextureChannel.RGB);
            channel.Add(TextureFormat.ETC2_RGBA8Crunched, TextureChannel.RGBA);
            #endregion
        }
    }

    public static class TextureExtension
    {
        public static TextureRes GetResolution(this Texture2D texture)
        {
            return (TextureRes)(texture.width);
        }
        public static void Dump(this Texture2D texture, string path, DumpFormat format = DumpFormat.TGA)
        {
            texture.filterMode = FilterMode.Point;
            byte[] bytes;
            switch (format)
            {
                case DumpFormat.TGA: { bytes = texture.EncodeToTGA(); break; } // Require Unity 2018.3 or above
                case DumpFormat.PNG: { bytes = texture.EncodeToPNG(); break; }
                case DumpFormat.JPG: { bytes = texture.EncodeToJPG(); break; }
                case DumpFormat.EXR: { bytes = texture.EncodeToEXR(Texture2D.EXRFlags.OutputAsFloat); break; }
                default: { bytes = texture.EncodeToPNG(); break; }
            }
            path += '.' + format.ToString();
            FileStream fs = File.Open(path, FileMode.Create);
            fs.Write(bytes, 0, bytes.Length);
            fs.Flush();
            fs.Close();
        }

        public static void Dump(this RenderTexture texture, string path, DumpFormat format = DumpFormat.TGA)
        {
            Texture2D buffer = new Texture2D(texture.width, texture.height, TextureFormat.RGBA32, false);
            buffer.filterMode = FilterMode.Point;
            RenderTexture.active = texture;
            buffer.ReadPixels(new Rect(0, 0, texture.width, texture.height), 0, 0);
            buffer.Apply();
            buffer.Dump(path, format);
        }

        public static void SetColor(this Texture2D texture, Color color)
        {
            for (int u = 0; u < texture.width; ++u)
                for (int v = 0; v < texture.height; ++v)
                    texture.SetPixel(u, v, color);
            texture.Apply();
        }

        public static Color32[] GetPixels32(this Texture2D texture, int X, int Y, int blockWidth, int blockHeight)
        {
            Color[] pixels = texture.GetPixels(X, Y, blockHeight, blockHeight);
            Color32[] pixels32 = new Color32[pixels.Length];
            for (int i = 0; i < pixels.Length; ++i)
            {
                pixels32[i] = pixels[i];
            }
            return pixels32;
        }

        public static Texture2D Resize(this Texture2D texture, int destRes, ResizeFilterMode filterMode = ResizeFilterMode.Bilinear)
        {
            int oRes = texture.width;
            int dRes = destRes;
            Texture2D dest = new Texture2D(destRes, destRes, texture.format, texture.mipmapCount > 1);
            float scaler = (float)oRes / dRes;
            for (int u = 0; u < dRes; ++u)
            {
                for (int v = 0; v < dRes; ++v)
                {
                    Color pixel = Color.white;
                    switch (filterMode)
                    {
                        case ResizeFilterMode.Bilinear:
                            {
                                Vector2 uv = new Vector2((u + 0.5f) / dRes, (v + 0.5f) / dRes);
                                pixel = texture.GetPixelBilinear(uv.x, uv.y);
                                break;
                            }
                        case ResizeFilterMode.Point:
                            {
                                Vector2 uv = new Vector2(u * scaler, v * scaler);
                                pixel = texture.GetPixel((int)uv.x, (int)uv.y);
                                break;
                            }
                    }
                    dest.SetPixel(u, v, pixel);
                }
            }
            dest.Apply();
            return dest;
        }

        public static Texture2D Resize(this Texture2D texture, TextureRes destRes, ResizeFilterMode filterMode = ResizeFilterMode.Bilinear)
        {
            return texture.Resize((int)destRes, filterMode);
        }

        public static Texture2D Clone(this Texture2D texture)
        {
            bool readable = texture.isReadable;
            Texture2D copy = new Texture2D(texture.width, texture.height, texture.format, texture.mipmapCount > 0);
            if (readable)
            {
                Color32[] pixels = texture.GetPixels32();
                copy.SetPixels32(pixels);
                copy.Apply();
            }
            else
            {
                string path = AssetDatabase.GetAssetPath(texture);
                TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                importer.isReadable = true;
                importer.SaveAndReimport();

                Color32[] pixels = texture.GetPixels32();
                copy.SetPixels32(pixels);
                copy.Apply();

                importer.isReadable = false;
                importer.SaveAndReimport();
            }
            return copy;
        }

        public static string GetInfo(this Texture2D texture)
        {
            StringBuilder strBuilder = new StringBuilder();
            strBuilder.AppendFormat("{0}x{1} ", texture.width, texture.height);
            strBuilder.Append(texture.format);
            float size = texture.GetRuntimeMemorySizeKB();
            if (size >= 1024)
            {
                size /= 1024f;
                strBuilder.AppendFormat(" {0}MB", size.ToString("F2"));
            }
            else
            {
                strBuilder.AppendFormat(" {0}KB", size.ToString("F2"));
            }
            return strBuilder.ToString();
        }
    }
}