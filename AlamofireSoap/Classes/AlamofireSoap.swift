//
//  AlamofireSoap.swift
//  AlamofireSoap
//
//  Created by Shakeeb Mancheri on 02/03/19.
//

import Alamofire

//Soap API Request creation
@discardableResult
public func soapRequest 
    (_ url: URLConvertible,
     soapmethod : String,
     soapparameters: Parameters? = nil,
     namespace : String = "http://tempuri.org")
    -> DataRequest
{
    
    let soapGenerator : SoapRequestManager!
    if let parameter = soapparameters {
        soapGenerator = SoapRequestManager(methodName: soapmethod, namespace: namespace, parameters: parameter)
    }
    else {
        soapGenerator = SoapRequestManager(methodName: soapmethod, namespace: namespace)
    }
    soapGenerator.generateSoapRequestElements()
    return Session.default.request(url, method: .post, parameters: [:], encoding: soapGenerator.getBody(), headers: soapGenerator.getHeaders())
}

extension String: ParameterEncoding {
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
}

class SoapRequestManager {
    
    private var methodName  : String
    private var namespace : String
    private var parameters : Parameters?
    private var soapBody : String = ""
    private var soapHeader : HTTPHeaders
    
    init(methodName : String,namespace: String,parameters: Parameters? = nil) {
        self.methodName = methodName
        self.namespace = namespace
        self.parameters = parameters
        self.soapHeader = HTTPHeaders(["Content-Type" : "text/xml; charset=utf-8"])
    }
    public func getBody() -> String {
        return soapBody
    }
    
    public func getHeaders()-> HTTPHeaders {
        return soapHeader
    }
    public func generateSoapRequestElements() {
        var soapString = ""
        if let parameters = parameters,parameters.count > 0 {
            var paramString : String = ""
            for (parameterkey,value) in parameters {
                paramString += getParameterSetString(parameterkey, value: String(describing: value))
            }
            soapString = "\(getStartStringWithMethod())\(paramString)\(self.endStringWithMethod())"
        }
        else {
            soapString = self.getNoParammethod()
        }
        self.soapBody = soapString
        self.soapHeader["SOAPAction"] = "\(self.namespace)/\(self.methodName)"
        self.soapHeader["Content-Length"] = "\(soapString.lengthOfBytes(using: .utf8))"
    }
    
    private func getStartStringWithMethod() -> String {
        let startString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body>\n<\(methodName) xmlns=\"\(namespace)/\">"
        return startString
    }
    private func endStringWithMethod() -> String{
        let endString = "</\(self.methodName)>\n</soap:Body>\n</soap:Envelope>"
        return endString
    }
    private func getNoParammethod() -> String {
        let startString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body>\n<\(self.methodName) xmlns=\"http://tempuri.org/\"/>\n</soap:Body>\n</soap:Envelope>"
        return startString
    }
    private func getParameterSetString(_ parameterName : String , value: String) -> String {
        let setParamString = "<\(parameterName)>\(escapeXML(value))</\(parameterName)>\n"
        return setParamString
    }

    /// Escapes characters that are not valid in XML character data. Without this a
    /// value containing "&" or "<" produces a malformed request body, which the
    /// server rejects before it reaches the method. The ampersand is replaced first,
    /// otherwise the escapes below would be escaped a second time.
    private func escapeXML(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }
}
