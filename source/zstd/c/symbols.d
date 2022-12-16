module zstd.c.symbols;

import std.stdint;

import zstd.c.typedefs;

extern (C) @nogc nothrow
{
    uint32_t ZSTD_versionNumber();
    char* ZSTD_versionString();

    int32_t ZSTD_minCLevel();
    int32_t ZSTD_defaultCLevel();
    int32_t ZSTD_maxCLevel();

    uint32_t ZSTD_isError(size_t);
    char* ZSTD_getErrorName(size_t);

    size_t ZSTD_compress(void* dst, size_t dstCapacity, const void* src, size_t srcSize, int32_t compressionLevel);
    size_t ZSTD_decompress(void* dst, size_t dstCapacity, void* src, size_t compressedSize);
    size_t ZSTD_findFrameCompressedSize(void* src, size_t srcSize);
    size_t ZSTD_compressBound(size_t srcSize);

    uint64_t ZSTD_getFrameContentSize(const void* src, size_t srcSize);

    struct ZSTD_CCtx_s;
    alias ZSTD_CCtx = ZSTD_CCtx_s;
    ZSTD_CCtx* ZSTD_createCCtx();
    void ZSTD_freeCCtx(ZSTD_CCtx* cctx);
    size_t ZSTD_compressCCtx(ZSTD_CCtx* cctx, void* dst, size_t dstCap, const void* src, size_t srcSize, int32_t compLvl);
    size_t ZSTD_compress2(ZSTD_CCtx* cctx, void* dst, size_t dstCapacity, void* src, size_t srcSize);
    size_t ZSTD_compress_usingDict(
        ZSTD_CCtx* ctx,
        void* dst,
        size_t dstCap,
        const void* src,
        size_t srcSize,
        const void* dict,
        size_t dictSize, int32_t compLvl);
    size_t ZSTD_compress_usingCDict(
        ZSTD_CCtx* cctx,
        void* dst,
        size_t dstCapacity,
        const void* src,
        size_t srcSize,
        const ZSTD_CDict* cdict);
    size_t ZSTD_CCtx_setParameter(ZSTD_CCtx* cctx, CompressionParameter param, int32_t value);
    size_t ZSTD_CCtx_setPledgedSrcSize(ZSTD_CCtx* cctx, uint64_t pledgedSrcSize);
    size_t ZSTD_CCtx_reset(ZSTD_CCtx* cctx, ResetDirective reset);
    Bounds ZSTD_cParam_getBounds(CompressionParameter);

    struct ZSTD_DCtx_s;
    alias ZSTD_DCtx = ZSTD_DCtx_s;
    ZSTD_DCtx* ZSTD_createDCtx();
    size_t ZSTD_freeDCtx(ZSTD_DCtx* dctx);
    size_t ZSTD_decompressDCtx(ZSTD_DCtx* dctx, void* dst, size_t dstCapacity, const void* src, size_t srcSize);
    size_t ZSTD_decompress_usingDict(
        ZSTD_DCtx* dctx,
        void* dst,
        size_t dstCap,
        const void* src,
        size_t srcSize,
        const void* dict,
        size_t dictSize);
    size_t ZSTD_DCtx_setParameter(ZSTD_DCtx* dctx, DecompressionParameter param, int32_t value);
    size_t ZSTD_DCtx_reset(ZSTD_DCtx* dctx, ResetDirective reset);
    Bounds ZSTD_dParam_getBounds(DecompressionParameter);

    alias ZSTD_CStream = ZSTD_CCtx;
    size_t ZSTD_initCStream(ZSTD_CStream* zcs, int32_t compressionLevel);
    size_t ZSTD_compressStream(ZSTD_CStream* zcs, OutBuffer* output, InBuffer* input);
    size_t ZSTD_compressStream2(ZSTD_CStream* cctx, OutBuffer* output, InBuffer* input, EndDirective endOp);
    size_t ZSTD_flushStream(ZSTD_CStream* zcs, OutBuffer* output);
    size_t ZSTD_endStream(ZSTD_CStream* zcs, OutBuffer* output);
    size_t ZSTD_CStreamInSize();
    size_t ZSTD_CStreamOutSize();

    alias ZSTD_DStream = ZSTD_DCtx;
    size_t ZSTD_DStreamInSize();
    size_t ZSTD_DStreamOutSize();

    struct ZSTD_CDict_s;
    alias ZSTD_CDict = ZSTD_CDict_s;
    ZSTD_CDict* ZSTD_createCDict(const void* dictBuffer, size_t dictSize, int compressionLevel);
    size_t ZSTD_freeCDict(ZSTD_CDict* CDict);
}
