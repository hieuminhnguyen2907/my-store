import crypto from "crypto";
import axios from "axios";

const payments = new Map();

function getMomoConfig() {
    return {
        partnerCode: process.env.MOMO_PARTNER_CODE || "",
        accessKey: process.env.MOMO_ACCESS_KEY || "",
        secretKey: process.env.MOMO_SECRET_KEY || "",
        momoEndpoint:
            process.env.MOMO_ENDPOINT ||
            "https://test-payment.momo.vn/v2/gateway/api/create",
        momoQueryEndpoint:
            process.env.MOMO_QUERY_ENDPOINT ||
            "https://test-payment.momo.vn/v2/gateway/api/query",
        redirectUrl:
            process.env.MOMO_RETURN_URL ||
            "http://localhost:5000/api/payments/momo/return",
        ipnUrl:
            process.env.MOMO_IPN_URL ||
            "http://localhost:5000/api/payments/momo/ipn",
    };
}

function createSignature(raw, secretKey) {
    return crypto.createHmac("sha256", secretKey).update(raw).digest("hex");
}

function ensureMomoConfig({ partnerCode, accessKey, secretKey }) {
    return Boolean(partnerCode && accessKey && secretKey);
}

function mapMomoResultToStatus(resultCode) {
    const code = Number(resultCode);
    if (code === 0) {
        return "PAID";
    }

    // Common MoMo non-final/finalizing statuses.
    const pendingCodes = new Set([1000, 7000, 7002, 9000]);
    if (pendingCodes.has(code)) {
        return "PENDING";
    }

    return "FAILED";
}

async function queryMomoTransactionStatus({ orderId, partnerCode, accessKey, secretKey, momoQueryEndpoint }) {
    const requestId = `${partnerCode}${Date.now()}_query`;
    const rawSignature =
        `accessKey=${accessKey}` +
        `&orderId=${orderId}` +
        `&partnerCode=${partnerCode}` +
        `&requestId=${requestId}`;

    const payload = {
        partnerCode,
        requestId,
        orderId,
        lang: "vi",
        signature: createSignature(rawSignature, secretKey),
    };

    const response = await axios.post(momoQueryEndpoint, payload, {
        headers: { "Content-Type": "application/json" },
        timeout: 30000,
    });

    const data = response.data || {};
    return {
        resultCode: Number(data.resultCode ?? -1),
        message: data.message || "",
        transId: data.transId || null,
        orderId: data.orderId || orderId,
        raw: data,
    };
}

export async function createMomoPayment(req, res) {
    try {
        const { partnerCode, accessKey, secretKey, momoEndpoint, redirectUrl, ipnUrl } =
            getMomoConfig();

        if (!ensureMomoConfig({ partnerCode, accessKey, secretKey })) {
            return res.status(500).json({
                ok: false,
                message:
                    "MoMo config is missing. Please set MOMO_PARTNER_CODE, MOMO_ACCESS_KEY and MOMO_SECRET_KEY.",
            });
        }

        const {
            amount,
            orderInfo = "Thanh toan don hang Big Cart",
            extraData = "",
            clientOrderId,
        } = req.body;

        const parsedAmount = Number(amount);
        if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
            return res.status(400).json({
                ok: false,
                message: "amount must be a valid positive number",
            });
        }

        const requestId = `${partnerCode}${Date.now()}`;
        const orderId = `${requestId}`;
        const requestType = "captureWallet";

        const rawSignature =
            `accessKey=${accessKey}` +
            `&amount=${Math.round(parsedAmount)}` +
            `&extraData=${extraData}` +
            `&ipnUrl=${ipnUrl}` +
            `&orderId=${orderId}` +
            `&orderInfo=${orderInfo}` +
            `&partnerCode=${partnerCode}` +
            `&redirectUrl=${redirectUrl}` +
            `&requestId=${requestId}` +
            `&requestType=${requestType}`;

        const payload = {
            partnerCode,
            accessKey,
            requestId,
            amount: String(Math.round(parsedAmount)),
            orderId,
            orderInfo,
            redirectUrl,
            ipnUrl,
            extraData,
            requestType,
            signature: createSignature(rawSignature, secretKey),
            lang: "vi",
        };

        payments.set(orderId, {
            orderId,
            requestId,
            clientOrderId: clientOrderId || null,
            amount: Math.round(parsedAmount),
            orderInfo,
            status: "PENDING",
            createdAt: new Date().toISOString(),
        });

        const momoResponse = await axios.post(momoEndpoint, payload, {
            headers: { "Content-Type": "application/json" },
            timeout: 30000,
        });

        const momoData = momoResponse.data || {};
        const payUrl = momoData.payUrl || "";

        if (!payUrl) {
            const record = payments.get(orderId);
            if (record) {
                record.status = "FAILED";
                record.error = momoData.message || "Cannot get payUrl from MoMo";
                record.updatedAt = new Date().toISOString();
            }

            return res.status(502).json({
                ok: false,
                message: "MoMo did not return payUrl",
                momo: momoData,
            });
        }

        return res.json({
            ok: true,
            orderId,
            clientOrderId: clientOrderId || null,
            payUrl,
            deeplink: momoData.deeplink || null,
            applink: momoData.applink || null,
            qrCodeUrl: momoData.qrCodeUrl || null,
            momo: momoData,
        });
    } catch (error) {
        const detail = error?.response?.data || error?.message || "Unknown error";
        return res.status(500).json({ ok: false, message: "Create payment failed", detail });
    }
}

export function getMomoPaymentStatus(req, res) {
    return (async () => {
        try {
            const { orderId } = req.params;
            const {
                partnerCode,
                accessKey,
                secretKey,
                momoQueryEndpoint,
            } = getMomoConfig();
            const localPayment = payments.get(orderId);

            if (localPayment && ["PAID", "FAILED"].includes(localPayment.status)) {
                return res.json({
                    ok: true,
                    orderId,
                    clientOrderId: localPayment.clientOrderId,
                    status: localPayment.status,
                    resultCode: localPayment.resultCode ?? null,
                    transId: localPayment.transId || null,
                    error: localPayment.error || null,
                    source: "local",
                    updatedAt: localPayment.updatedAt || localPayment.createdAt,
                });
            }

            if (!ensureMomoConfig({ partnerCode, accessKey, secretKey })) {
                if (!localPayment) {
                    return res.status(404).json({ ok: false, message: "Payment not found" });
                }

                return res.json({
                    ok: true,
                    orderId,
                    clientOrderId: localPayment.clientOrderId,
                    status: localPayment.status,
                    resultCode: localPayment.resultCode ?? null,
                    transId: localPayment.transId || null,
                    error: localPayment.error || null,
                    source: "local-no-config",
                    updatedAt: localPayment.updatedAt || localPayment.createdAt,
                });
            }

            const remote = await queryMomoTransactionStatus({
                orderId,
                partnerCode,
                accessKey,
                secretKey,
                momoQueryEndpoint,
            });
            const mappedStatus = mapMomoResultToStatus(remote.resultCode);

            const mergedPayment = {
                ...(localPayment || {
                    orderId,
                    clientOrderId: null,
                    createdAt: new Date().toISOString(),
                }),
                status: mappedStatus,
                resultCode: remote.resultCode,
                transId: remote.transId,
                error: mappedStatus === "FAILED" ? remote.message : null,
                updatedAt: new Date().toISOString(),
            };

            payments.set(orderId, mergedPayment);

            return res.json({
                ok: true,
                orderId,
                clientOrderId: mergedPayment.clientOrderId,
                status: mergedPayment.status,
                resultCode: mergedPayment.resultCode,
                transId: mergedPayment.transId || null,
                error: mergedPayment.error || null,
                source: "momo-query",
                updatedAt: mergedPayment.updatedAt,
                momo: remote.raw,
            });
        } catch (error) {
            const detail = error?.response?.data || error?.message || "Unknown error";
            return res.status(500).json({
                ok: false,
                message: "Failed to query payment status",
                detail,
            });
        }
    })();
}

export function momoIpnHandler(req, res) {
    try {
        const { accessKey, secretKey } = getMomoConfig();
        const body = req.body || {};

        const rawSignature =
            `accessKey=${body.accessKey || accessKey}` +
            `&amount=${body.amount || ""}` +
            `&extraData=${body.extraData || ""}` +
            `&message=${body.message || ""}` +
            `&orderId=${body.orderId || ""}` +
            `&orderInfo=${body.orderInfo || ""}` +
            `&orderType=${body.orderType || ""}` +
            `&partnerCode=${body.partnerCode || ""}` +
            `&payType=${body.payType || ""}` +
            `&requestId=${body.requestId || ""}` +
            `&responseTime=${body.responseTime || ""}` +
            `&resultCode=${body.resultCode || ""}`;

        const signature = createSignature(rawSignature, secretKey);
        if (signature !== (body.signature || "")) {
            return res.status(400).json({ ok: false, message: "Invalid signature" });
        }

        const orderId = `${body.orderId || ""}`;
        const resultCode = Number(body.resultCode || -1);

        const payment = payments.get(orderId);
        if (payment) {
            if (resultCode === 0) {
                payment.status = "PAID";
                payment.resultCode = resultCode;
                payment.transId = body.transId || null;
            } else {
                payment.status = "FAILED";
                payment.resultCode = resultCode;
                payment.error = body.localMessage || body.message || `code:${resultCode}`;
            }
            payment.updatedAt = new Date().toISOString();
            payments.set(orderId, payment);
        }

        return res.json({ ok: true });
    } catch (error) {
        return res.status(500).json({ ok: false, message: "IPN handler failed", detail: error?.message || "Unknown error" });
    }
}

export function momoReturnHandler(req, res) {
    const query = req.query || {};
    const orderId = `${query.orderId || ""}`;
    const resultCode = `${query.resultCode || ""}`;
    const message = `${query.message || ""}`;

    const deepLink = `bigcart://payment-return?orderId=${encodeURIComponent(orderId)}&resultCode=${encodeURIComponent(resultCode)}&message=${encodeURIComponent(message)}`;

    return res
        .status(200)
        .set("Content-Type", "text/html; charset=utf-8")
        .send(`<!doctype html>
<html lang="vi">
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Quay lại Big Cart</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; padding: 24px; background: #f7f8fb; color: #111; }
            .card { max-width: 560px; margin: 40px auto; background: #fff; border-radius: 14px; padding: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
            h2 { margin-top: 0; }
            .btn { display: inline-block; margin-top: 12px; padding: 12px 16px; border-radius: 10px; text-decoration: none; background: #111; color: #fff; }
            .hint { color: #555; margin-top: 10px; font-size: 14px; }
            pre { white-space: pre-wrap; word-break: break-word; background: #f3f4f6; padding: 10px; border-radius: 8px; }
        </style>
    </head>
    <body>
        <div class="card">
            <h2>Thanh toán hoàn tất</h2>
            <p>Bạn có thể tự quay lại ứng dụng Big Cart để tiếp tục.</p>
            <a class="btn" href="${deepLink}">Mở lại Big Cart</a>
            <p class="hint">Nút này chỉ mở app thủ công, hệ thống không tự động chuyển nữa.</p>
            <pre>${JSON.stringify(query, null, 2)}</pre>
        </div>
    </body>
</html>`);
}
