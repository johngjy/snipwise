#pragma once

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>
#include <shlobj.h>
#include <shobjidl.h>
#include <objidl.h>

// 数据对象实现，用于提供拖拽数据
class DataObject : public IDataObject {
public:
    DataObject(const std::wstring& filePath);
    virtual ~DataObject();

    // IUnknown接口
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppvObject) override;
    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    // IDataObject接口
    HRESULT STDMETHODCALLTYPE GetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium) override;
    HRESULT STDMETHODCALLTYPE GetDataHere(FORMATETC* pFormatEtc, STGMEDIUM* pMedium) override;
    HRESULT STDMETHODCALLTYPE QueryGetData(FORMATETC* pFormatEtc) override;
    HRESULT STDMETHODCALLTYPE GetCanonicalFormatEtc(FORMATETC* pFormatEtcIn, FORMATETC* pFormatEtcOut) override;
    HRESULT STDMETHODCALLTYPE SetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium, BOOL fRelease) override;
    HRESULT STDMETHODCALLTYPE EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC** ppEnumFormatEtc) override;
    HRESULT STDMETHODCALLTYPE DAdvise(FORMATETC* pFormatEtc, DWORD advf, IAdviseSink* pAdvSink, DWORD* pdwConnection) override;
    HRESULT STDMETHODCALLTYPE DUnadvise(DWORD dwConnection) override;
    HRESULT STDMETHODCALLTYPE EnumDAdvise(IEnumSTATDATA** ppEnumAdvise) override;

private:
    std::wstring m_filePath;
    long m_refCount;
};

// 拖拽源实现，处理拖拽操作
class DropSource : public IDropSource {
public:
    DropSource();
    virtual ~DropSource();

    // IUnknown接口
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppvObject) override;
    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    // IDropSource接口
    HRESULT STDMETHODCALLTYPE QueryContinueDrag(BOOL fEscapePressed, DWORD grfKeyState) override;
    HRESULT STDMETHODCALLTYPE GiveFeedback(DWORD dwEffect) override;

private:
    long m_refCount;
};

// Windows平台的拖拽处理器，处理Flutter的拖拽请求
class Win32DragHandler {
public:
    Win32DragHandler();
    ~Win32DragHandler();

    // 注册到Flutter插件注册器
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
    
    // 处理Flutter方法调用
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

private:
    // 开始拖拽操作
    void StartDragOperation(
        const std::string& file_path,
        double origin_x,
        double origin_y,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    // 清理临时文件
    void CleanupTempFile(const std::string& file_path);
    
    // 转换UTF-8到宽字符
    std::wstring Utf8ToWide(const std::string& str);
    
    // 记录日志
    void Log(const std::string& message);
}; 