// types/youtube-transcript-api.d.ts
declare module 'youtube-transcript-api' {
  export class YoutubeTranscript {
    static fetchTranscript(videoId: string, options?: { lang?: string }): Promise<any[]>;
  }
}