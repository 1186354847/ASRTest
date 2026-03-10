/**
 * @Desc: 合成鉴权
 * @author: leon
 * @datetime: 2024/8/13
 */
import { buffer, url, util } from '@kit.ArkTS'
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export class AuthUtils {

  static async assembleRequestUrl(requestUrl: string, apiKey: string, apiSecret: string) {
    let tempUrl = url.URL.parseURL(requestUrl);
    try {
      // 获取日期 "EEE, dd MMM yyyy HH:mm:ss z" , eg. Tue, 13 Aug 2024 05:17:21 GMT
      const date = new Date().toUTCString();
      let host = tempUrl.host;
      const port = tempUrl.port; // port >0 说明url 中带有port
      if (port) {
        host = `${host}:${port}`;
      }
      // 构建签名计算所需参数
      const builder = `host: ${host}\n` +
        `date: ${date}\n` +
        `GET ${tempUrl.pathname} HTTP/1.1`;
      // 使用hmac-sha256计算签名
      let key = await AuthUtils.genSymKeyByData(apiSecret);
      let mac = cryptoFramework.createMac('SHA256');
      await mac.init(key);
      await mac.update({ data: new Uint8Array(buffer.from(builder, 'utf-8').buffer) });
      let macResult = await mac.doFinal();
      // console.info('HMAC result:' + macResult.data);
      let sha = new util.Base64Helper().encodeToStringSync(macResult.data);
      // 拼接
      const authorization =
        `api_key="${apiKey}", algorithm="hmac-sha256", headers="host date request-line", signature="${sha}"`;
      // 拼接地址
      const urlParams = new url.URLParams();
      let authBase64 = new util.Base64Helper().encodeToStringSync(AuthUtils.stringToUint8Array(authorization));
      urlParams.append("authorization",authBase64);
      urlParams.append("date",date);
      urlParams.append("host",host);
      return `https://${host}${tempUrl.pathname}?${urlParams.toString()}`;
    } catch (e) {
      console.debug("鉴权失败", JSON.stringify(e));
      return undefined;
    }
  }

  private static async genSymKeyByData(apiSecret: string) {
    let symKeyBlob: cryptoFramework.DataBlob =
      { data: new Uint8Array(buffer.from(apiSecret, 'utf-8').buffer) };
    let aesGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
    let symKey = await aesGenerator.convertKey(symKeyBlob);
    console.info('convertKey success');
    return symKey;
  }

  private static stringToUint8Array(str: string) {
    return new Uint8Array(buffer.from(str,'utf-8').buffer);
  }
}
