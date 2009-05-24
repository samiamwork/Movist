////////////////////////////////////////////////////////////////////////////////
// copied & modified from MPlayer.

#ifndef _MPLAYER_SPUDEC_H
#define _MPLAYER_SPUDEC_H

//#include "libvo/video_out.h"

// moved from spudec.c
typedef struct _spudec_packet_t {
    unsigned char *packet;
    unsigned int palette[4];
    unsigned int alpha[4];
    unsigned int control_start;	/* index of start of control data */
    unsigned int current_nibble[2]; /* next data nibble (4 bits) to be
     processed (for RLE decoding) for
     even and odd lines */
    int deinterlace_oddness;	/* 0 or 1, index into current_nibble */
    unsigned int start_col, end_col;
    unsigned int start_row, end_row;
    unsigned int width, height, stride;
    unsigned int start_pts, end_pts;
    struct _spudec_packet_t *next;
} spudec_packet_t;

typedef struct {
    spudec_packet_t *queue_head;
    spudec_packet_t *queue_tail;
    unsigned int global_palette[16];
    unsigned int orig_frame_width, orig_frame_height;
    unsigned char* packet;
    size_t packet_reserve;	/* size of the memory pointed to by packet */
    unsigned int packet_offset;	/* end of the currently assembled fragment */
    unsigned int packet_size;	/* size of the packet once all fragments are assembled */
    unsigned int packet_pts;	/* PTS for this packet */
    unsigned int palette[4];
    unsigned int alpha[4];
    unsigned int cuspal[4];
    unsigned int custom;
    unsigned int now_pts;
    unsigned int start_pts, end_pts;
    unsigned int start_col, end_col;
    unsigned int start_row, end_row;
    unsigned int width, height, stride;
    size_t image_size;		/* Size of the image buffer */
    unsigned char *image;		/* Grayscale value */
    unsigned char *aimage;	/* Alpha value */
    unsigned int scaled_frame_width, scaled_frame_height;
    unsigned int scaled_start_col, scaled_start_row;
    unsigned int scaled_width, scaled_height, scaled_stride;
    size_t scaled_image_size;
    unsigned char *scaled_image;
    unsigned char *scaled_aimage;
    int auto_palette; /* 1 if we lack a palette and must use an heuristic. */
    int font_start_level;  /* Darkest value used for the computed font */
    void* hw_spu;//vo_functions_t *hw_spu;
    int spu_changed;
    unsigned int forced_subs_only;     /* flag: 0=display all subtitle, !0 display only forced subtitles */
    unsigned int is_forced_sub;         /* true if current subtitle is a forced subtitle */
} spudec_handle_t;

void spudec_heartbeat(void *this, unsigned int pts100);
void spudec_assemble(void *this, unsigned char *packet, unsigned int len, unsigned int pts100);
//void spudec_draw(void *this, void (*draw_alpha)(int x0,int y0, int w,int h, unsigned char* src, unsigned char *srca, int stride));
//void spudec_draw_scaled(void *this, unsigned int dxs, unsigned int dys, void (*draw_alpha)(int x0,int y0, int w,int h, unsigned char* src, unsigned char *srca, int stride));
//void spudec_update_palette(void *this, unsigned int *palette);
//void *spudec_new_scaled(unsigned int *palette, unsigned int frame_width, unsigned int frame_height);
void *spudec_new_scaled_vobsub(unsigned int *palette, unsigned int *cuspal, unsigned int custom, unsigned int frame_width, unsigned int frame_height);
//void *spudec_new(unsigned int *palette);
void spudec_free(void *this);
void spudec_reset(void *this);	// called after seek
//int spudec_visible(void *this); // check if spu is visible
//void spudec_set_font_factor(void * this, double factor); // sets the equivalent to ffactor
//void spudec_set_hw_spu(void *this, vo_functions_t *hw_spu);
int spudec_changed(void *this);
//void spudec_calc_bbox(void *me, unsigned int dxs, unsigned int dys, unsigned int* bbox);
//void spudec_draw_scaled(void *me, unsigned int dxs, unsigned int dys, void (*draw_alpha)(int x0,int y0, int w,int h, unsigned char* src, unsigned char *srca, int stride));
//void spudec_set_forced_subs_only(void * const this, const unsigned int flag);
#endif

