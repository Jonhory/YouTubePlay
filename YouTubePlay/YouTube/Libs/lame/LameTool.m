//
//  LameTool.m
//  YouTube
//
//  Created by Jonhory on 2019/2/20.
//  Copyright © 2019 jk. All rights reserved.
//

#import "LameTool.h"
#import "lame.h"

@implementation LameTool

+ (void)cafToMp3:(NSString*)cafFileName {
    NSString * _mp3FilePath = [cafFileName stringByReplacingOccurrencesOfString:@".m4a" withString:@".mp3"];
    NSLog(@"_mp3FilePath : ", _mp3FilePath);
    
    @try {
        int read, write;
        FILE *pcm = fopen([cafFileName cStringUsingEncoding:1], "rb");
        FILE *mp3 = fopen([_mp3FilePath cStringUsingEncoding:1], "wb");
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"转换错误： %@",[exception description]);
    }
    @finally {
        //Detrming the size of mp3 file
        NSFileManager *fileManger = [NSFileManager defaultManager];
        NSData *data = [fileManger contentsAtPath:_mp3FilePath];
        NSString* str = [NSString stringWithFormat:@"%lu K",[data length]/1024];
        NSLog(@"size of mp3=%@",str);
        
    }
}

+ (NSString *)audioCAFtoMP3:(NSString *)wavPath {
    
    NSString *cafFilePath = wavPath;
    
    NSString *mp3FilePath = [wavPath stringByReplacingOccurrencesOfString:@".m4a" withString:@".mp3"];
    NSLog(@"_mp3FilePath : %@", mp3FilePath);
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame,1);//设置1为单通道，默认为2双通道
        lame_set_in_samplerate(lame, 44100.0);
        lame_set_VBR(lame, vbr_default);
        
        lame_set_brate(lame,8);
        
        lame_set_mode(lame,3);
        
        lame_set_quality(lame,2);
        
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        return mp3FilePath;
    }
}
    
@end
