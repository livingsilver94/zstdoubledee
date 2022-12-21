module zstd.context;

import std.stdint;

import zstd.c.symbols;
public import zstd.c.typedefs : Bounds,
    CompressionParameter,
    DecompressionParameter,
    EndDirective,
    InBuffer,
    OutBuffer,
    ResetDirective;
import zstd.common;
import zstd.dict;

version (unittest)
{
    import std.algorithm.comparison : equal;
    import std.exception : assertNotThrown, assertThrown;

    import zstd.func;
}

public alias CompressionStream = CompressionContext;
public alias DecompressionStream = DecompressionContext;

class CompressionContext
{
    this()
    {
        ptr = ZSTD_createCCtx();
    }

    ~this()
    {
        ZSTD_freeCCtx(ptr);
    }

    size_t compress(void[] dst, const void[] src, CompressionLevel lvl)
    {
        const auto size = ZSTD_compressCCtx(ptr, dst.ptr, dst.length, src.ptr, src.length, lvl);
        ZSTDException.throwIfError(size);
        return size;
    }

    unittest
    {
        auto ctx = new CompressionContext();
        ubyte[] src = [1, 2, 3];
        ubyte[] dst = new ubyte[compressBound(src.length)];
        const auto size = ctx.compress(dst, src, 1);
        assert(size > 0);
        assert(!equal(dst, new ubyte[dst.length]));

        assertThrown!ZSTDException(ctx.compress(null, src, 1));
    }

    size_t compress(void[] dst, const void[] src)
    {
        const auto size = ZSTD_compress2(
            ptr,
            dst.ptr,
            dst.length,
            src.ptr,
            src.length);
        ZSTDException.throwIfError(size);
        return size;
    }

    unittest
    {
        auto ctx = new CompressionContext();
        ubyte[] src = [1, 2, 3];
        ubyte[] dst = new ubyte[compressBound(src.length)];
        const auto size = ctx.compress(dst, src);
        assert(size > 0);
        assert(!equal(dst, new ubyte[dst.length]));

        assertThrown!ZSTDException(ctx.compress(null, src));
    }

    size_t compressUsingDict(void[] dst, const void[] src, const void[] dict, CompressionLevel lvl)
    {
        const auto size = ZSTD_compress_usingDict(
            ptr,
            dst.ptr,
            dst.length,
            src.ptr,
            src.length,
            dict.ptr,
            dict.length,
            lvl);
        ZSTDException.throwIfError(size);
        return size;
    }

    unittest
    {
        auto ctx = new CompressionContext();
        ubyte[] src = [1, 2, 3];
        ubyte[] dst = new ubyte[compressBound(src.length)];
        const auto size = ctx.compressUsingDict(dst, src, null, 1);
        assert(size > 0);
        assert(!equal(dst, new ubyte[dst.length]));

        assertThrown!ZSTDException(ctx.compressUsingDict(null, src, null, 1));
    }

    size_t compressUsingDict(void[] dst, const void[] src, const CompressionDict cdict)
    {
        const auto size = ZSTD_compress_usingCDict(ptr,
            dst.ptr,
            dst.length,
            src.ptr,
            src.length,
            cdict.ptr);
        ZSTDException.throwIfError(size);
        return size;
    }

    unittest
    {
        auto ctx = new CompressionContext();
        auto dict = new CompressionDict(null, 1);
        ubyte[] src = [1, 2, 3];
        ubyte[] dst = new ubyte[compressBound(src.length)];
        const auto size = ctx.compressUsingDict(dst, src, dict);
        assert(size > 0);
        assert(!equal(dst, new ubyte[dst.length]));

        assertThrown!ZSTDException(ctx.compressUsingDict(null, src, dict));
    }

    void loadDictionary(const void[] dict)
    {
        const auto errCode = ZSTD_CCtx_loadDictionary(ptr, dict.ptr, dict.length);
        ZSTDException.throwIfError(errCode);
    }

    unittest
    {
        auto ctx = new CompressionContext();
        assertNotThrown(ctx.loadDictionary(null));
        /* I can't make this throw exceptions 😐 */
    }

    void refDict(const CompressionDict dict)
    {
        const auto errCode = ZSTD_CCtx_refCDict(ptr, dict.ptr);
        ZSTDException.throwIfError(errCode);
    }

    unittest
    {
        auto ctx = new CompressionContext();
        auto dict = new CompressionDict(new ubyte[1], 1);
        assertNotThrown(ctx.refDict(dict));
        /* I can't make this throw exceptions 😐 */
    }

    void refPrefix(const void[] prefix)
    {
        const auto errCode = ZSTD_CCtx_refPrefix(ptr, prefix.ptr, prefix.length);
        ZSTDException.throwIfError(errCode);
    }

    unittest
    {
        auto ctx = new CompressionContext();
        assertNotThrown(ctx.refPrefix(null));
        /* I can't make this throw exceptions 😐 */
    }

    void setParameter(CompressionParameter param, int value)
    {
        const auto errCode = ZSTD_CCtx_setParameter(ptr, param, value);
        ZSTDException.throwIfError(errCode);
    }

    unittest
    {
        auto ctx = new CompressionContext();
        assertNotThrown(ctx.setParameter(CompressionParameter.CompressionLevel, 1));
        assertThrown!ZSTDException(ctx.setParameter(cast(CompressionParameter) 0, 0));
    }

    void setPledgedSrcSize(uint64_t pledgedSrcSize)
    {
        const auto errCode = ZSTD_CCtx_setPledgedSrcSize(ptr, pledgedSrcSize);
        ZSTDException.throwIfError(errCode);
    }

    unittest
    {
        auto ctx = new CompressionContext();
        assertNotThrown(ctx.setPledgedSrcSize(1));

        auto buf = OutBuffer();
        ctx.streamEnd(&buf); /* Can only set pledged src size at init stage. */
        assertThrown!ZSTDException(ctx.setPledgedSrcSize(1));
    }

    void streamInit(CompressionLevel lvl)
    {
        const auto errcode = ZSTD_initCStream(ptr, lvl);
        ZSTDException.throwIfError(errcode);
    }

    size_t streamCompress(OutBuffer* output, InBuffer* input)
    {
        const auto size = ZSTD_compressStream(ptr, output, input);
        ZSTDException.throwIfError(size);
        return size;
    }

    size_t streamCompress(OutBuffer* output, InBuffer* input, EndDirective endOp)
    {
        const auto remain = ZSTD_compressStream2(ptr, output, input, endOp);
        ZSTDException.throwIfError(remain);
        return remain;
    }

    size_t streamFlush(OutBuffer* output)
    {
        const auto size = ZSTD_flushStream(ptr, output);
        ZSTDException.throwIfError(
            size);
        return size;
    }

    size_t streamEnd(OutBuffer* output)
    {
        const auto size = ZSTD_endStream(ptr, output);
        ZSTDException.throwIfError(size);
        return size;
    }

    static size_t streamInSize()
    {
        return ZSTD_CStreamInSize();
    }

    static size_t streamOutSize()
    {
        return ZSTD_CStreamOutSize();
    }

    size_t sizeOf()
    {
        return ZSTD_sizeof_CCtx(ptr);
    }

    void reset(ResetDirective directive)
    {
        const auto errCode = ZSTD_CCtx_reset(ptr, directive);
        ZSTDException.throwIfError(errCode);
    }

private:
    ZSTD_CCtx* ptr;
}

class DecompressionContext
{
    this()
    {
        ptr = ZSTD_createDCtx();
    }

    ~this()
    {
        ZSTD_freeDCtx(ptr);
    }

    size_t decompress(void[] dst, const void[] src)
    {
        const auto size = ZSTD_decompressDCtx(ptr, dst.ptr, dst
                .length, src.ptr, src.length);
        ZSTDException.throwIfError(size);
        return size;
    }

    size_t decompressUsingDict(void[] dst, const void[] src, const void[] dict)
    {
        const auto size = ZSTD_decompress_usingDict(
            ptr,
            dst.ptr,
            dst.length,
            src.ptr,
            src.length,
            dict.ptr,
            dict.length);
        ZSTDException.throwIfError(
            size);
        return size;
    }

    size_t decompressUsingDict(void[] dst, const void[] src, const DecompressionDict ddict)
    {
        const auto size = ZSTD_decompress_usingDDict(ptr,
            dst.ptr,
            dst.length,
            src.ptr,
            src.length,
            ddict.ptr);
        ZSTDException.throwIfError(
            size);
        return size;
    }

    void loadDictionary(const void[] dict)
    {
        const auto errCode = ZSTD_DCtx_loadDictionary(ptr, dict
                .ptr, dict.length);
        ZSTDException.throwIfError(
            errCode);
    }

    void refDict(
        const DecompressionDict dict)
    {
        const auto errCode = ZSTD_DCtx_refDDict(ptr, dict
                .ptr);
        ZSTDException.throwIfError(
            errCode);
    }

    void refPrefix(const void[] prefix)
    {
        const auto errCode = ZSTD_DCtx_refPrefix(ptr, prefix
                .ptr, prefix.length);
        ZSTDException.throwIfError(
            errCode);
    }

    void setParameter(DecompressionParameter param, int value)
    {
        const auto errCode = ZSTD_DCtx_setParameter(ptr, param, value);
        ZSTDException.throwIfError(
            errCode);
    }

    static size_t streamInSize()
    {
        return ZSTD_DStreamInSize();
    }

    static size_t streamOutSize()
    {
        return ZSTD_DStreamOutSize();
    }

    size_t sizeOf()
    {
        return ZSTD_sizeof_DCtx(ptr);
    }

    void reset(ResetDirective directive)
    {
        const auto errCode = ZSTD_DCtx_reset(ptr, directive);
        ZSTDException.throwIfError(
            errCode);
    }

private:
    ZSTD_DCtx* ptr;
}
