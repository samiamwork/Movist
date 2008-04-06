//
//  Movist
//
//  Copyright 2006 ~ 2008 Yong-Hoe Kim. All rights reserved.
//      Yong-Hoe Kim  <cocoable@gmail.com>
//
//  This file is part of Movist.
//
//  Movist is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 3 of the License, or
//  (at your option) any later version.
//
//  Movist is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "MMovie.h"

@implementation MMovie (Codec)

#define CASE_FFCODEC_MCODEC(fc, mc) \
        case CODEC_ID_##fc : \
            codecId = MCODEC_##mc; \
            fs = @""#fc; ms = @""#mc; \
            break

#define CASE_FFCODEC_______(fc) \
        case CODEC_ID_##fc : \
            fs = @""#fc; \
            break

#define IF_FFCODEC_MCODEC(fcs, mc) \
        if ([fourCC isEqualToString:fcs]) \
            codecId = MCODEC_##mc, \
            ms = @""#mc

+ (int)videoCodecIdFromFFmpegCodecId:(int)ffmpegCodecId fourCC:(NSString*)fourCC
{
    // at first, init with ffmpegCodeId for codecs without fourCC
    int codecId = MCODEC_ETC_;
    NSString* fs = @"???", *ms = @"???";
    switch (ffmpegCodecId) {
        CASE_FFCODEC_MCODEC(NONE,            ETC_);
        CASE_FFCODEC_MCODEC(MPEG1VIDEO,      MPEG1);
        CASE_FFCODEC_MCODEC(MPEG2VIDEO,      MPEG2);
        CASE_FFCODEC_MCODEC(MPEG2VIDEO_XVMC, MPEG2);
        CASE_FFCODEC_______(H261);
        CASE_FFCODEC_MCODEC(H263,            H263);
        CASE_FFCODEC_MCODEC(RV10,            RV10);
        CASE_FFCODEC_MCODEC(RV20,            RV20);
        CASE_FFCODEC_MCODEC(MJPEG,           MJPEG);
        CASE_FFCODEC_MCODEC(MJPEGB,          MJPEG);
        CASE_FFCODEC_______(LJPEG);
        CASE_FFCODEC_______(SP5X);
        CASE_FFCODEC_______(JPEGLS);
        CASE_FFCODEC_MCODEC(MPEG4,           MPEG4);
        CASE_FFCODEC_______(RAWVIDEO);
        CASE_FFCODEC_MCODEC(MSMPEG4V1,       MPG4);
        CASE_FFCODEC_MCODEC(MSMPEG4V2,       MP42);
        CASE_FFCODEC_MCODEC(MSMPEG4V3,       MP43);
        CASE_FFCODEC_MCODEC(WMV1,            WMV1);
        CASE_FFCODEC_MCODEC(WMV2,            WMV2);
        CASE_FFCODEC_MCODEC(H263P,           H263);
        CASE_FFCODEC_MCODEC(H263I,           H263);
        CASE_FFCODEC_MCODEC(FLV1,            FLV);
        CASE_FFCODEC_MCODEC(SVQ1,            SVQ1);
        CASE_FFCODEC_MCODEC(SVQ3,            SVQ3);
        CASE_FFCODEC_______(DVVIDEO);
        CASE_FFCODEC_MCODEC(HUFFYUV,         HUFFYUV);
        CASE_FFCODEC_______(CYUV);
        CASE_FFCODEC_MCODEC(H264,            H264);
        CASE_FFCODEC_MCODEC(INDEO3,          INDEO3);
        CASE_FFCODEC_MCODEC(VP3,             VP3);
        CASE_FFCODEC_MCODEC(THEORA,          THEORA);
        CASE_FFCODEC_______(ASV1);
        CASE_FFCODEC_______(ASV2);
        CASE_FFCODEC_______(FFV1);
        CASE_FFCODEC_______(4XM);
        CASE_FFCODEC_______(VCR1);
        CASE_FFCODEC_______(CLJR);
        CASE_FFCODEC_______(MDEC);
        CASE_FFCODEC_______(ROQ);
        CASE_FFCODEC_______(INTERPLAY_VIDEO);
        CASE_FFCODEC_______(XAN_WC3);
        CASE_FFCODEC_______(XAN_WC4);
        CASE_FFCODEC_______(RPZA);
        CASE_FFCODEC_MCODEC(CINEPAK,         CINEPAK);
        CASE_FFCODEC_______(WS_VQA);
        CASE_FFCODEC_______(MSRLE);
        CASE_FFCODEC_______(MSVIDEO1);
        CASE_FFCODEC_______(IDCIN);
        CASE_FFCODEC_______(8BPS);
        CASE_FFCODEC_______(SMC);
        CASE_FFCODEC_______(FLIC);
        CASE_FFCODEC_______(TRUEMOTION1);
        CASE_FFCODEC_______(VMDVIDEO);
        CASE_FFCODEC_______(MSZH);
        CASE_FFCODEC_______(ZLIB);
        CASE_FFCODEC_______(QTRLE);
        CASE_FFCODEC_______(SNOW);
        CASE_FFCODEC_______(TSCC);
        CASE_FFCODEC_______(ULTI);
        CASE_FFCODEC_______(QDRAW);
        CASE_FFCODEC_______(VIXL);
        CASE_FFCODEC_______(QPEG);
        CASE_FFCODEC_MCODEC(XVID,            XVID);
        CASE_FFCODEC_______(PNG);
        CASE_FFCODEC_______(PPM);
        CASE_FFCODEC_______(PBM);
        CASE_FFCODEC_______(PGM);
        CASE_FFCODEC_______(PGMYUV);
        CASE_FFCODEC_______(PAM);
        CASE_FFCODEC_______(FFVHUFF);
        CASE_FFCODEC_MCODEC(RV30,            RV30);
        CASE_FFCODEC_MCODEC(RV40,            RV40);
        CASE_FFCODEC_MCODEC(VC1,             VC1);
        CASE_FFCODEC_MCODEC(WMV3,            WMV3);
        CASE_FFCODEC_______(LOCO);
        CASE_FFCODEC_______(WNV1);
        CASE_FFCODEC_______(AASC);
        CASE_FFCODEC_MCODEC(INDEO2,          INDEO2);
        CASE_FFCODEC_______(FRAPS);
        CASE_FFCODEC_______(TRUEMOTION2);
        CASE_FFCODEC_______(BMP);
        CASE_FFCODEC_______(CSCD);
        CASE_FFCODEC_______(MMVIDEO);
        CASE_FFCODEC_______(ZMBV);
        CASE_FFCODEC_______(AVS);
        CASE_FFCODEC_______(SMACKVIDEO);
        CASE_FFCODEC_______(NUV);
        CASE_FFCODEC_______(KMVC);
        CASE_FFCODEC_______(FLASHSV);
        CASE_FFCODEC_______(CAVS);
        CASE_FFCODEC_______(JPEG2000);
        CASE_FFCODEC_______(VMNC);
        CASE_FFCODEC_MCODEC(VP5,             VP5);
        CASE_FFCODEC_MCODEC(VP6,             VP6);
        CASE_FFCODEC_MCODEC(VP6F,            VP6F);
        CASE_FFCODEC_______(TARGA);
        CASE_FFCODEC_______(DSICINVIDEO);
        CASE_FFCODEC_______(TIERTEXSEQVIDEO);
        CASE_FFCODEC_______(TIFF);
        CASE_FFCODEC_______(GIF);
        CASE_FFCODEC_______(FFH264);
        CASE_FFCODEC_______(DXA);
        CASE_FFCODEC_______(DNXHD);
        CASE_FFCODEC_______(THP);
        CASE_FFCODEC_______(SGI);
        CASE_FFCODEC_______(C93);
        CASE_FFCODEC_______(BETHSOFTVID);
        CASE_FFCODEC_______(PTX);
        CASE_FFCODEC_______(TXD);
        CASE_FFCODEC_______(VP6A);
        CASE_FFCODEC_______(AMV);
        CASE_FFCODEC_______(VB);
        CASE_FFCODEC_______(PCX);
        CASE_FFCODEC_______(SUNRAST);
        CASE_FFCODEC_MCODEC(MPEG2TS,         MPEG2);
    }

    // update detailed-codec-info by fourCC
    if (fourCC) {
             IF_FFCODEC_MCODEC(@"DIV1", DIV1);
        else IF_FFCODEC_MCODEC(@"DIV2", DIV2);
        else IF_FFCODEC_MCODEC(@"DIV3", DIV3);
        else IF_FFCODEC_MCODEC(@"DIV4", DIV4);
        else IF_FFCODEC_MCODEC(@"DIV5", DIV5);
        else IF_FFCODEC_MCODEC(@"DIV6", DIV6);
        else IF_FFCODEC_MCODEC(@"DIVX", DIVX);
        else IF_FFCODEC_MCODEC(@"DX50", DX50);
        else IF_FFCODEC_MCODEC(@"XVID", XVID);
        else IF_FFCODEC_MCODEC(@"mp4v", MP4V);
        else IF_FFCODEC_MCODEC(@"MPG4", MPG4);
        else IF_FFCODEC_MCODEC(@"MP42", MP42);
        else IF_FFCODEC_MCODEC(@"MP43", MP43);
        else IF_FFCODEC_MCODEC(@"MP4S", MP4S);
        else IF_FFCODEC_MCODEC(@"M4S2", M4S2);
        else IF_FFCODEC_MCODEC(@"AP41", AP41);
        else IF_FFCODEC_MCODEC(@"RMP4", RMP4);
        else IF_FFCODEC_MCODEC(@"SEDG", SEDG);
        else IF_FFCODEC_MCODEC(@"FMP4", FMP4);
        else IF_FFCODEC_MCODEC(@"BLZ0", BLZ0);
        else IF_FFCODEC_MCODEC(@"avc1", AVC1);
        else IF_FFCODEC_MCODEC(@"X264", X264);
        else IF_FFCODEC_MCODEC(@"x264", X264);
        else IF_FFCODEC_MCODEC(@"vc-1", VC1);
        else IF_FFCODEC_MCODEC(@"WVC1", WVC1);
        // [3IV2],[IV31],[IV32]
    }
    TRACE(@"detected video codec: [%d]:\"%@\" ==> [%d]:\"%@\"",
          ffmpegCodecId, fs, codecId, ms);
    return codecId;
}

+ (int)audioCodecIdFromFFmpegCodecId:(int)ffmpegCodecId
{
    int codecId = MCODEC_ETC_;
    NSString* fs = @"???", *ms = @"???";
    switch (ffmpegCodecId) {
        CASE_FFCODEC_MCODEC(PCM_S16LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S16BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U16LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U16BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S8,         PCM);
        CASE_FFCODEC_MCODEC(PCM_U8,         PCM);
        CASE_FFCODEC_MCODEC(PCM_MULAW,      PCM);
        CASE_FFCODEC_MCODEC(PCM_ALAW,       PCM);
        CASE_FFCODEC_MCODEC(PCM_S32LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S32BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U32LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U32BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S24LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S24BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U24LE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_U24BE,      PCM);
        CASE_FFCODEC_MCODEC(PCM_S24DAUD,    PCM);
        CASE_FFCODEC_MCODEC(PCM_ZORK,       PCM);
        CASE_FFCODEC_MCODEC(PCM_S16LE_PLANAR,PCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_QT,   ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_WAV,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_DK3,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_DK4,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_WS,   ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_SMJPEG,ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_MS,       ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_4XM,      ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_XA,       ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_ADX,      ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_EA,       ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_G726,     ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_CT,       ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_SWF,      ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_YAMAHA,   ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_SBPRO_4,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_SBPRO_3,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_SBPRO_2,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_THP,      ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_AMV,  ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_EA_R1,    ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_EA_R3,    ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_EA_R2,    ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_EA_SEAD,ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_IMA_EA_EACS,ADPCM);
        CASE_FFCODEC_MCODEC(ADPCM_EA_XAS,   ADPCM);
        CASE_FFCODEC_MCODEC(AMR_NB,         AMR);
        CASE_FFCODEC_MCODEC(AMR_WB,         AMR);
        CASE_FFCODEC_MCODEC(RA_144,         RA);
        CASE_FFCODEC_MCODEC(RA_288,         RA);
        CASE_FFCODEC_MCODEC(ROQ_DPCM,       DPCM);
        CASE_FFCODEC_MCODEC(INTERPLAY_DPCM, DPCM);
        CASE_FFCODEC_MCODEC(XAN_DPCM,       DPCM);
        CASE_FFCODEC_MCODEC(SOL_DPCM,       DPCM);
        CASE_FFCODEC_MCODEC(MP2,            MP2);
        CASE_FFCODEC_MCODEC(MP3,            MP3);
        CASE_FFCODEC_MCODEC(AAC,            AAC);
        CASE_FFCODEC_MCODEC(AC3,            AC3);
        CASE_FFCODEC_MCODEC(DTS,            DTS);
        CASE_FFCODEC_MCODEC(VORBIS,         VORBIS);
        CASE_FFCODEC_MCODEC(DVAUDIO,        DVAUDIO);
        CASE_FFCODEC_MCODEC(WMAV1,          WMAV1);
        CASE_FFCODEC_MCODEC(WMAV2,          WMAV2);
        CASE_FFCODEC_MCODEC(MACE3,          MACE);
        CASE_FFCODEC_MCODEC(MACE6,          MACE);
        CASE_FFCODEC_______(VMDAUDIO);
        CASE_FFCODEC_______(SONIC);
        CASE_FFCODEC_______(SONIC_LS);
        CASE_FFCODEC_MCODEC(FLAC,           FLAC);
        CASE_FFCODEC_______(MP3ADU);
        CASE_FFCODEC_______(MP3ON4);
        CASE_FFCODEC_______(SHORTEN);
        CASE_FFCODEC_MCODEC(ALAC,           ALAC);
        CASE_FFCODEC_______(WESTWOOD_SND1);
        CASE_FFCODEC_______(GSM);
        CASE_FFCODEC_MCODEC(QDM2,           QDM2);
        CASE_FFCODEC_______(COOK);
        CASE_FFCODEC_______(TRUESPEECH);
        CASE_FFCODEC_MCODEC(TTA,            TTA);
        CASE_FFCODEC_______(SMACKAUDIO);
        CASE_FFCODEC_______(QCELP);
        CASE_FFCODEC_MCODEC(WAVPACK,        WAVPACK);
        CASE_FFCODEC_______(DSICINAUDIO);
        CASE_FFCODEC_______(IMC);
        CASE_FFCODEC_______(MUSEPACK7);
        CASE_FFCODEC_______(MLP);
        CASE_FFCODEC_______(GSM_MS);
        CASE_FFCODEC_______(ATRAC3);
        CASE_FFCODEC_______(VOXWARE);
        CASE_FFCODEC_______(APE);
        CASE_FFCODEC_______(NELLYMOSER);
        CASE_FFCODEC_______(MUSEPACK8);
        CASE_FFCODEC_MCODEC(SPEEX,          SPEEX);
    }
    TRACE(@"detected audio codec: [%d]:\"%@\" ==> [%d]:\"%@\"",
          ffmpegCodecId, fs, codecId, ms);
    return codecId;
}

@end
