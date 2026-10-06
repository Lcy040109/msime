#pragma once

#include "Private.h"

class CLingyaoIME;

class CEditSessionBase : public ITfEditSession
{
  public:
    CEditSessionBase(_In_ CLingyaoIME *pTextService, _In_ ITfContext *pContext);
    virtual ~CEditSessionBase();

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, _Outptr_ void **ppvObj);
    STDMETHODIMP_(ULONG) AddRef(void);
    STDMETHODIMP_(ULONG) Release(void);

    // ITfEditSession
    virtual STDMETHODIMP DoEditSession(TfEditCookie ec) = 0;

  protected:
    ITfContext *_pContext;
    CLingyaoIME *_pTextService;

  private:
    LONG _refCount; // COM ref count
};
