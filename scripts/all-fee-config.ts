export type IntegratorFeeConfig = {
  integratorTakerAddresses: {
    [key: number]: string,
  },
  socketTakerAddresses: {
    [key: number]: string,
  },
  integratorName: string,
  integratorId: number,
  totalFeeInBps: number,
  integratorPart: number,
  socketPart: number,
}

export const allIntegratorFeeConfig: IntegratorFeeConfig[] = [];
