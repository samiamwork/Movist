////////////////////////////////////////////////////////////////////////////////
// copied & modified from MPlayer.

#ifndef MPLAYER_VOBSUB_H
#define MPLAYER_VOBSUB_H

extern void *vobsub_open(const char *subname, const char *const ifo, const int force, void** spu);
//extern void vobsub_reset(void *vob);
extern int vobsub_get_next_packet(void *vobhandle, int index, void** data, int* timestamp);
extern void vobsub_close(void *this);
extern unsigned int vobsub_get_indexes_count(void * /* vobhandle */);
extern char *vobsub_get_id(void * /* vobhandle */, unsigned int /* index */);
/*
extern void* vobsub_make(const char* idx, void** spu);
extern void vobsub_add_sub(void* vobhandle, int sid, unsigned char* data, int dataSize, int pts);
 */
extern void vobsub_init_spudec(void* vobhandle, int sid);

#endif /* MPLAYER_VOBSUB_H */

