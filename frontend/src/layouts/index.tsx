import { useState, useEffect } from 'react'
import { Outlet, Link, history } from 'umi'
import { useWallet, ConnectModal } from '@suiet/wallet-kit'
import sui from '@/assets/sui.png'
const navigation = [
  { name: 'Home', href: '/' },
  { name: 'Search', href: '/search' },
  { name: 'Upload', href: '/upload' },
]

export default function Example() {
  const wallet = useWallet()
  const { connected } = wallet
  const [showModal, setShowModal] = useState(false)
  const [showDisconnected, setShowDisconnected] = useState(false)
  return (
    <div className="isolate bg-white">
      <div className="absolute inset-x-0 top-[-10rem] -z-10 transform-gpu overflow-hidden blur-3xl sm:top-[-20rem]">
        <svg
          className="relative left-[calc(50%-11rem)] -z-10 h-[21.1875rem] max-w-none -translate-x-1/2 rotate-[30deg] sm:left-[calc(50%-30rem)] sm:h-[42.375rem]"
          viewBox="0 0 1155 678"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fill="url(#45de2b6b-92d5-4d68-a6a0-9b9b2abad533)"
            fillOpacity=".3"
            d="M317.219 518.975L203.852 678 0 438.341l317.219 80.634 204.172-286.402c1.307 132.337 45.083 346.658 209.733 145.248C936.936 126.058 882.053-94.234 1031.02 41.331c119.18 108.451 130.68 295.337 121.53 375.223L855 299l21.173 362.054-558.954-142.079z"
          />
          <defs>
            <linearGradient
              id="45de2b6b-92d5-4d68-a6a0-9b9b2abad533"
              x1="1155.49"
              x2="-78.208"
              y1=".177"
              y2="474.645"
              gradientUnits="userSpaceOnUse"
            >
              <stop stopColor="#9089FC" />
              <stop offset={1} stopColor="#FF80B5" />
            </linearGradient>
          </defs>
        </svg>
      </div>
      <div className="px-6 pt-6 lg:px-8">
        <div>
          <nav
            className="flex h-9 items-center justify-between"
            aria-label="Global"
          >
            <div className="flex lg:min-w-0 lg:flex-1" aria-label="Global">
              <a
                href="https://github.com/RandyPen/certificate-SBT"
                className="-m-1.5 p-1.5"
              >
                <img className="h-8" src={sui} alt="" />
              </a>
            </div>
            <div className="hidden lg:flex lg:min-w-0 lg:flex-1 lg:justify-center lg:gap-x-12">
              {navigation.map((item) => (
                <span
                  key={item.name}
                  onClick={() => {
                    history.push(item.href)
                  }}
                  className="font-semibold text-gray-900 hover:text-gray-900 cursor-pointer text-xl"
                >
                  {item.name}
                </span>
              ))}
            </div>
            <div className="flex min-w-0 flex-1 justify-end">
              {connected ? (
                <span
                  onClick={() => setShowDisconnected(!showDisconnected)}
                  className="relative cursor-default inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20"
                >
                  {wallet.address}
                  {showDisconnected ? (
                    <span
                      onClick={() => {
                        wallet.disconnect()
                      }}
                      className="top-10 right-0 absolute cursor-default inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20"
                    >
                      DisConnect
                    </span>
                  ) : (
                    <></>
                  )}
                </span>
              ) : (
                <ConnectModal
                  open={showModal}
                  onOpenChange={(open) => setShowModal(open)}
                >
                  <span className="cursor-default inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20">
                    Log in
                  </span>
                </ConnectModal>
              )}
            </div>
          </nav>
        </div>
      </div>
      {/* <main className="m-auto container border border-red-400 border-solid pt-4"> */}
      <main className="m-auto container pt-4">
        <Outlet></Outlet>
      </main>
    </div>
  )
}
